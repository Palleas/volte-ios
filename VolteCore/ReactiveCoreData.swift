//
//  ReactiveCoreData.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-02.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import CoreData
import ReactiveSwift

extension NSManagedObjectContext: ReactiveExtensionsProvider {}

enum CoreDataError: Error {
    case saving(Error)
}
extension Reactive where Base: NSManagedObjectContext {
    func save() -> SignalProducer<(), CoreDataError> {
        return SignalProducer { [base = self.base] sink, disposable in
            do {
                try base.save()
                sink.sendCompleted()
            } catch let error {
                sink.send(error: .saving(error))
            }
        }
    }
}
