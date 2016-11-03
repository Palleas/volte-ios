//
//  AppDelegate.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit
import VolteCore
import CoreData
import ReactiveSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let storageController = StorageController()
    private let accountController = AccountController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()

        storageController.load().startWithCompleted {}

        accountController.account.producer
            .skipNil()
            .flatMap(.latest) { (account) -> SignalProducer<[Message], TimelineError> in
                print("We have an account, let's download messages")
                return TimelineDownloader(account: account, storageController: self.storageController).fetchItems()
            }
            .startWithResult { result in
                print("Result.value = \(result.value)")
                print("Result.error = \(result.error)")
                self.storageController.refresh()
            }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootViewController(accountController: accountController, storageController: storageController)
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        try! self.storageController.container.viewContext.save()
    }

}
