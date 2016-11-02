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

public struct Item {
    public let uid: UInt32
    public let content: String
    public let email: String
    public let date: Date
    public let attachments: [Data]
}

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

public class TimelineContentProvider {
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

    public func fetchMessage(with uid: UInt32) -> SignalProducer<Item, TimelineError> {
        return SignalProducer { sink, disposable in
            let operation = self.session.fetchMessageByUIDOperation(withFolder: "INBOX", uid: uid)
            operation?.start({ (error, messageContent) in
                if let _ = error {
                    sink.send(error: .internalError)
                } else if let messageContent = messageContent {
                    let parser = MCOMessageParser(data: messageContent)!
                    guard let parts = (parser.mainPart() as? MCOMultipart)?.parts as? [MCOAttachment] else {
                        sink.send(error: .decodingError(uid))
                        return
                    }
                    let voltePart = parts.filter { $0.mimeType == "application/ld+json" }.first!

                    let payload = JSON(data: voltePart.data)

                    let attachments = parts
                        .filter { $0.mimeType == "image/jpg" }
                        .flatMap { $0.data }

                    sink.send(value: Item(
                        uid: uid,
                        content: payload["text"].string ?? "No content for \(uid)",
                        email: parser.header.from.mailbox ?? "",
                        date: parser.header.date,
                        attachments: attachments
                    ))
                    sink.sendCompleted()
                } else {
                    sink.send(error: .internalError)
                }
            })

            disposable.add {
                operation?.cancel()
            }
        }

    }

    public func fetchItems() -> SignalProducer<[Message], TimelineError> {

        let context = self.storageController.container.newBackgroundContext()

        return self.storageController
            .lastFetchedUID()
            .promoteErrors(TimelineError.self)
            .flatMap(.latest, transform: { (uid) -> SignalProducer<MCOIMAPMessage, TimelineError> in
                return self.fetchShallowMessages(start: UInt64(uid + 1))
            })
            .flatMap(.concat, transform: { (message) -> SignalProducer<Item, TimelineError> in
                return self
                    .fetchMessage(with: message.uid)
                    .flatMapError { _ in SignalProducer.empty }
            })
            .flatMap(.concat, transform: { (item) -> SignalProducer<Message, TimelineError> in
                let producer = SignalProducer<Message, TimelineError> { sink, _ in
                    let message = Message(entity: Message.entity(), insertInto: context)
                    message.author = item.email
                    message.content = item.content
                    message.postedAt = item.date as NSDate?
                    message.uid = Int32(item.uid)

                    sink.send(value: message)
                    sink.sendCompleted()
                    print("Imported message \(item.uid)")
                }
                return producer.start(on: StorageScheduler(context: context))
            })
            .collect()
            .flatMap(.latest, transform: { (messages) -> SignalProducer<[Message], TimelineError> in
                return SignalProducer { sink, _ in
                    do {
                        try context.save()
                        sink.send(value: messages)
                        sink.sendCompleted()
                    } catch {
                        sink.send(error: TimelineError.internalError)
                    }
                }
            })
    }
}
