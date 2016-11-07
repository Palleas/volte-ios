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

class VoltePersistentContainer: NSPersistentContainer {
    override class func defaultDirectoryURL() -> URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        print("Path = \(path)")

        return URL(fileURLWithPath: path)
    }
}

public class StorageController {
    public enum StorageError: Error {
        case initializationError
    }

    public let container: NSPersistentContainer

    public let messages = MutableProperty<[Message]>([])

    public init() {
        let bundle = Bundle(for: type(of: self))
        let mom = NSManagedObjectModel.mergedModel(from: [bundle])!
        container = VoltePersistentContainer(name: "Volte", managedObjectModel: mom)
    }

    public func load() -> SignalProducer<(), StorageError> {
        return SignalProducer { sink, _ in
            self.container.loadPersistentStores { (description, error) in
                if let _ = error {
                    sink.send(error: .initializationError)
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }

    public func lastFetchedUID() -> SignalProducer<Int32, NoError> {
        return SignalProducer { sink, _ in
            let request = NSFetchRequest<Message>(entityName: Message.entity().name!)
            request.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: false)]
            request.fetchLimit = 1

            let uid = try! self.container.viewContext.fetch(request).first?.uid ?? 1
            print("UID = \(uid)")
            
            sink.send(value: uid)
            sink.sendCompleted()
        }
    }

    public func refresh() {
        print("Refreshing container store...")
        let request = NSFetchRequest<Message>(entityName: Message.entity().name!)
        request.sortDescriptors = [NSSortDescriptor(key: "postedAt", ascending: false)]

        let producer = self.container.viewContext.reactive.fetch(request)
            .flatMapError { _ in return SignalProducer<[Message], NoError>(values: []) }

        messages <~ producer
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
