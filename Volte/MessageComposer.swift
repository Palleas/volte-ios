//
//  MessageComposer.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift

class MessageComposer {
    // TODO
    private static let recipients = ["romain.pouclet@gmail.com", "marc@weistroff.net"]

    enum ComposingError: Error {
        case internalError
    }

    private let session: MCOSMTPSession = {
        let session = MCOSMTPSession()
        session.hostname = "SSL0.OVH.NET"
        session.port = 465;
        session.connectionType = .TLS

        return session
    }()

    private let account: Account

    init(account: Account) {
        self.account = account

        session.username = account.username;
        session.password = account.password;
    }

    func sendMessage(with content: String) -> SignalProducer<String, ComposingError> {
        return SignalProducer { sink, disposable in
            let builder = MCOMessageBuilder()
            builder.header.from = MCOAddress(mailbox: self.account.username)
            builder.header.to = MessageComposer.recipients.map { MCOAddress(mailbox: $0) }
            builder.header.subject = "Coucou"

            builder.textBody = content
//            let payload = ["something": "something-else"]
//            let attachment = MCOAttachment(rfc822Message: try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted))!
//            attachment.mimeType = "application/ld+json"
//            builder.addAttachment(attachment)

            let operation = self.session.sendOperation(with: builder.data())
            operation?.start { (error) in
                print("Send error = \(error)")
                if let error = error {
                    sink.send(error: .internalError)
                } else {
                    sink.send(value: "Yay")
                    sink.sendCompleted()
                }
            }
            disposable.add {
                operation?.cancel()
            }
        }
    }
}
