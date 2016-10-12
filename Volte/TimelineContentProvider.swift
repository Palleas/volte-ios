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
struct Account {
    let username: String
    let password: String
}

struct Item {
    let content: String
}

enum TimelineError: Error {
    case internalError
    case decodingError(UInt32)
}

class TimelineContentProvider {
    private let session = MCOIMAPSession()

    init() {
        session.hostname = "SSL0.OVH.NET"
        session.port = 993
        session.connectionType = .TLS
    }

    func authenticate(with account: Account) -> TimelineContentProvider {
        session.username = account.username
        session.password = account.password

        return self
    }

    func fetchShallowMessages() -> SignalProducer<MCOIMAPMessage, TimelineError> {
        print("Fetching shallow messages")

        return SignalProducer { sink, disposable in
            let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
            let operation = self.session.fetchMessagesOperation(withFolder: "INBOX", requestKind: .structure, uids: uids)
            operation?.start { (error, messages, vanishedMessages) in
                if let _ = error {
                    sink.send(error: .internalError)
                } else if let messages = messages as? [MCOIMAPMessage] {
                    messages.forEach { sink.send(value: $0) }
                    sink.sendCompleted()
                } else {
                    sink.send(error: .internalError)
                }
            }

            disposable.add {
                print("Cancelling operation")
                operation?.cancel()
            }
        }
    }

    func fetchMessage(with uid: UInt32) -> SignalProducer<Item, TimelineError> {
        print("Fetching message with uid \(uid)")
        return SignalProducer { sink, disposable in
            let operation = self.session.fetchMessageByUIDOperation(withFolder: "INBOX", uid: uid)
            operation?.start({ (error, messageContent) in
                if let _ = error {
                    sink.send(error: .internalError)
                } else if let messageContent = messageContent {
                    let parser = MCOMessageParser(data: messageContent)
                    print("content = \(parser?.mainPart())")

                    let payload = JSON(data: messageContent)

                    sink.send(value: Item(content: payload["text"].string ?? "No content for \(uid)"))
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

    func fetchItems() -> SignalProducer<Item, TimelineError> {
        print("Fetching messages")

        return fetchShallowMessages()
            .flatMap(.concat, transform: { (message) -> SignalProducer<Item, TimelineError> in
                return self.fetchMessage(with: message.uid)
            })
    }
}
