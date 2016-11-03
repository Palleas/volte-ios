//
//  ReactiveMailCore.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-02.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import MailCore
import ReactiveSwift

extension MCOIMAPFetchContentOperation: ReactiveExtensionsProvider {}

enum MailCoreError: Error {
    case internalError(Error)
    case unknownError
}

extension Reactive where Base: MCOIMAPFetchContentOperation {
    func fetch() -> SignalProducer<MCOMessageParser, MailCoreError> {
        return SignalProducer { [base = self.base] sink, disposable in
            disposable += {
                base.cancel()
            }

            base.start { (error, data) in
                if let error = error {
                    sink.send(error: .internalError(error))
                } else if let data = data {
                    sink.send(value: MCOMessageParser(data: data))
                    sink.sendCompleted()
                } else {
                    // Something weird happened and me don't have data and no error
                    sink.send(error: .unknownError)
                }
            }
        }
    }
}
