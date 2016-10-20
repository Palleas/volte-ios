//
//  AppDelegate.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let accountController = AccountController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()
        

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootViewController(accountController: accountController)
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

}
