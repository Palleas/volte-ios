//
//  TimelineContentProvider.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-02.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import CoreData

public class TimelineContentProvider {

    private let storageController: StorageController

    public init(storageController: StorageController) {
        self.storageController = storageController
    }

    public func fetchMessages() -> SignalProducer<[Message], NoError> {
        let request = NSFetchRequest<Message>(entityName: Message.entity().name!)
        request.sortDescriptors = [NSSortDescriptor(key: "postedAt", ascending: false)]

        return self.storageController.container.viewContext.reactive.fetch(request)
            .flatMapError { _ in return SignalProducer<[Message], NoError>(values: []) }
    }

}
