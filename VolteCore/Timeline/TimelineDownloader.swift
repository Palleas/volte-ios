//
//  TimelineContentProvider.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift
import SwiftyJSON
import Result
import MailCore
import CoreData

public enum TimelineError: Error {
    case internalError
    case authenticationError
    case decodingError(UInt32)
}

public func ==(lhs: TimelineError, rhs: TimelineError) -> Bool {
    switch (lhs, rhs) {
    case (.internalError, .internalError): return true
    case (.authenticationError, .authenticationError): return true
    case (.decodingError(let message1), .decodingError(let message2)) where message1 == message2: return true
    default: return true
    }
}

public class TimelineDownloader {
    private let session = MCOIMAPSession()
    private let storageController: StorageController

    public init(account: Account, storageController: StorageController) {
        session.hostname = "voltenetwork.xyz"
        session.port = 993
        session.connectionType = .TLS
        session.username = account.username
        session.password = account.password

        self.storageController = storageController
    }

    public func fetchShallowMessages(start: UInt64 = 1) -> SignalProducer<MCOIMAPMessage, TimelineError> {
        print("Fetching shallow messages")

        return SignalProducer { sink, disposable in
            let uids = MCOIndexSet(range: MCORangeMake(start, UINT64_MAX))
            let operation = self.session.fetchMessagesOperation(withFolder: "INBOX", requestKind: .structure, uids: uids)
            operation?.start { (error, messages, vanishedMessages) in
                if let error = error as? NSError, error.code == MCOErrorCode.authentication.rawValue {
                    sink.send(error: .authenticationError)
                } else if let _ = error {
                    sink.send(error: .internalError)
                } else if let messages = messages {
                    messages.forEach { sink.send(value: $0) }
                    sink.sendCompleted()
                } else {
                    sink.send(error: .internalError)
                }
            }

            disposable.add {
                operation?.cancel()
            }
        }
    }

    public func fetchMessage(with uid: UInt32) -> SignalProducer<Message, TimelineError> {
        print("Fetching message with id \(uid)")
        let operation = self.session.fetchMessageOperation(withFolder: "INBOX", uid: uid)!
        return operation.reactive.fetch()
            .flatMapError { _ in return SignalProducer<MCOMessageParser, TimelineError>(error: .decodingError(uid)) }
            .attemptMap { message in
                guard let parts = (message.mainPart() as? MCOMultipart)?.parts as? [MCOAttachment] else {
                    print("Invalid content for message \(uid)")
                    return Result(error: TimelineError.decodingError(uid))
                }

                let from = message.header.from.mailbox
                let date = message.header.date

                guard let voltePart = parts.filter({ $0.mimeType == "application/ld+json" }).first else {
                    print("No main content for message \(uid)")
                    return Result(error: TimelineError.decodingError(uid))
                }

                // Build the main message
                let payload = JSON(data: voltePart.data)
                let message = Message(entity: Message.entity(), insertInto: nil)
                message.author = from
                message.content = payload["text"].string
                message.postedAt = date as NSDate?
                message.uid = Int32(uid)

                // Extract attachments
                let attachments: [MCOAttachment] = parts.filter { $0.mimeType == "image/jpg" }

                let savedAttachments = attachments.map { messageAttachment -> Attachment in
                        let attachment = Attachment(entity: Attachment.entity(), insertInto: nil)
                        attachment.data = messageAttachment.data as NSData?
                        attachment.message = message
                        return attachment
                }
                message.addToAttachments(NSSet(array: savedAttachments))
                print("Message has \(message.attachments?.count) attachments")

                return Result(value: message)
            }
            .flatMapError { error in
                print("Got error \(error)")
                return SignalProducer.empty
            }
    }

    public func fetchItems() -> SignalProducer<[Message], TimelineError> {
        let context = self.storageController.managedObjectContext

        return self.storageController
            .lastFetchedUID()
            .promoteErrors(TimelineError.self)
            .flatMap(.latest, transform: { uid in
                return self.fetchShallowMessages(start: UInt64(uid + 1))
            })
            .flatMap(.concat, transform: { message in
                return self.fetchMessage(with: message.uid)
            })
            .collect()
            .flatMap(.latest, transform: { messages -> SignalProducer<[Message], TimelineError> in
                print("Fetched \(messages.count) messages")
                messages.forEach { message in
                    context.insert(message)

                    message.attachments?.forEach { attachment in
                        context.insert(attachment as! NSManagedObject)
                    }
                }

                return context.reactive.save()
                    .flatMap(.latest) { self.storageController.managedObjectContext.reactive.save() }
                    .flatMap(.latest) { self.storageController.privateObjectContext.reactive.save() }
                    .flatMapError { _ in SignalProducer<() ,TimelineError>(error: .internalError) }
                    .flatMap(.latest, transform: { (_) -> SignalProducer<[Message], TimelineError> in
                        print("Saved background context and returning \(messages.count) messages")
                        return SignalProducer<[Message], TimelineError>(value: messages)
                    })

            })
    }
}
