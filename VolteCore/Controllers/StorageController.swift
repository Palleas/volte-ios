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
import Result

public class StorageController {
    public enum StorageError: Error {
        case initializationError
    }

    public let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    public let privateObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

    public let messages = MutableProperty<[Message]>([])

    public init() {
        let bundle = Bundle(for: type(of: self))
        let mom = NSManagedObjectModel.mergedModel(from: [bundle])!

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        privateObjectContext.persistentStoreCoordinator = coordinator

        managedObjectContext.parent = privateObjectContext

        messages.producer.startWithValues {
            print("Messages = \($0)")
        }

    }

    public func load() -> SignalProducer<(), StorageError> {
        return SignalProducer { sink, _ in
            guard let psc = self.privateObjectContext.persistentStoreCoordinator else {
                sink.send(error: .initializationError)
                return
            }

            var options = [AnyHashable: Any]()
            options[NSMigratePersistentStoresAutomaticallyOption] = true
            options[NSInferMappingModelAutomaticallyOption] = true
            options[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]

            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return }
            let storeURL = documentsURL.appendingPathComponent("DataModel.sqlite")

            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
                sink.send(value: ())
                sink.sendCompleted()
            } catch {
                sink.send(error: .initializationError)
            }
        }
    }

    public func lastFetchedUID() -> SignalProducer<Int32, NoError> {
        return SignalProducer { sink, _ in
            let request = NSFetchRequest<Message>(entityName: Message.entity().name!)
            request.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: false)]
            request.fetchLimit = 1

            let uid = try! self.managedObjectContext.fetch(request).first?.uid ?? 1

            sink.send(value: uid)
            sink.sendCompleted()
        }
    }

    public func refresh() {
        print("Refreshing container store...")
        let request = NSFetchRequest<Message>(entityName: Message.entity().name!)
        request.sortDescriptors = [NSSortDescriptor(key: "postedAt", ascending: false)]

        let producer = self.managedObjectContext.reactive.fetch(request)
            .flatMapError { error -> SignalProducer<[Message], NoError> in
                print("Error during refresh \(error)")
                return SignalProducer<[Message], NoError>(values: [])
            }

        messages <~ producer
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let spawn = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        spawn.parent = managedObjectContext

        return spawn
    }

    public func wipe() throws {
        let urls = privateObjectContext.persistentStoreCoordinator?.persistentStores.flatMap {
            $0.url
        }
        
        try urls?.forEach { try FileManager.default.removeItem(at: $0) }
    }

    public func save() -> SignalProducer<(), CoreDataError> {
        return managedObjectContext.reactive.save()
            .flatMap(.latest) { self.privateObjectContext.reactive.save() }
    }
}

class StorageScheduler: SchedulerProtocol {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func schedule(_ action: @escaping () -> Void) -> Disposable? {
        let disposable = SimpleDisposable()

        context.perform { () -> Void in
            guard !disposable.isDisposed else {
                return
            }

            action()
        }

        return disposable
    }
}
