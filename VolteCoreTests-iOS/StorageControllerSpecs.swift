//
//  StorageControllerSpecs.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-19.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import Nimble
import Quick
import Result
import ReactiveCocoa
import ReactiveSwift
import CoreData

@testable import VolteCore

class StorageControllerSpecs: QuickSpec {

    override func spec() {
        var storage: StorageController!

        
        beforeEach {
            storage = StorageController()

            let r = storage.load().wait()
            expect(r.error).to(beNil())
        }

        afterEach {
            try! storage.wipe()
            storage = nil
        }

        context("Fresh install") {
            describe("last fetched id") {
                it("should return 1 as the last fetched id") {
                    let result = storage.lastFetchedUID().first()

                    expect(result!.value).to(equal(1))
                }
            }
        }

        context("database already has some message") {
            beforeEach {
                let moc = storage.privateObjectContext

                let _: [Message] = (0...10).map {
                    let m = Message(context: moc)
                    m.uid = Int32($0)
                    return m
                }

                let result = moc.reactive.save().wait()
                expect(result.error).to(beNil())
            }
            
            describe("last fetched id") {
                it("should return 10") {
                    let result = storage.lastFetchedUID().first()

                    expect(result!.value).to(equal(10))
                }
            }
        }

        describe("spawning a child context") {
            it("should have the viewContext as parent") {
                let spawned = storage.newBackgroundContext()
                expect(spawned.parent).to(equal(storage.managedObjectContext))
            }

            it("should merge the changes into the parent") {
                let spawned = storage.newBackgroundContext()
                expect(spawned.hasChanges).to(beFalse())

                let message = Message(context: spawned)
                message.uid = 34

                expect(spawned.hasChanges).to(beTrue())

                _ = spawned.reactive.save().wait()

                expect(spawned.hasChanges).to(beFalse())
                expect(storage.managedObjectContext.hasChanges).to(beTrue())
            }
        }

        describe("Saving to disk") {
            it("should save everything") {
                let message = Message(context: storage.managedObjectContext)
                message.uid = 34

                expect(storage.managedObjectContext.hasChanges).to(beTrue())

                _ = storage.save().wait()

                expect(storage.managedObjectContext.hasChanges).to(beFalse())
                expect(storage.privateObjectContext.hasChanges).to(beFalse())
            }
        }
    }
}
