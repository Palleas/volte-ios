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
import MailCore

public struct Item {
    public let uid: UInt32
    public let content: String
    public let email: String
    public let date: Date
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
    
    public init(account: Account) {
        session.hostname = "voltenetwork.xyz"
        session.port = 993
        session.connectionType = .TLS
        session.username = account.username
        session.password = account.password

    }

    public func fetchShallowMessages() -> SignalProducer<MCOIMAPMessage, TimelineError> {
        print("Fetching shallow messages")

        return SignalProducer { sink, disposable in
            let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
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

                    sink.send(value: Item(
                        uid: uid,
                        content: payload["text"].string ?? "No content for \(uid)",
                        email: parser.header.from.mailbox ?? "",
                        date: parser.header.date
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

    public func fetchItems() -> SignalProducer<Item, TimelineError> {
        return fetchShallowMessages()
            .flatMap(.concat, transform: { (message) -> SignalProducer<Item, TimelineError> in
                return self
                    .fetchMessage(with: message.uid)
                    .flatMapError { _ in SignalProducer.empty }
            })
    }
}
