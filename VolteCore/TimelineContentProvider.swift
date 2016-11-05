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

    public var messages: SignalProducer<[Message], NoError> {
        return storageController.messages.producer
    }

    public init(storageController: StorageController) {
        self.storageController = storageController
    }

}
