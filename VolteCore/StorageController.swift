//
//  StorageController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-01.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import CoreData
import ReactiveSwift

public class StorageController {
    public enum StorageError: Error {
        case initializationError
    }

    private let container: NSPersistentContainer

    public init() {
        let bundle = Bundle(for: type(of: self))
        let mom = NSManagedObjectModel.mergedModel(from: [bundle])!
        container = NSPersistentContainer(name: "Volte", managedObjectModel: mom)
    }

    public func load() -> SignalProducer<(), StorageError> {
        return SignalProducer { sink, _ in
            self.container.loadPersistentStores { (_, error) in
                if let _ = error {
                    sink.send(error: .initializationError)
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }
}
