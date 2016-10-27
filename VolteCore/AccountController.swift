//
//  AccountController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift
import RGLockboxIOS

public struct Account {
    let username: String
    let password: String
}

public protocol AccountControllerType {
    var account: MutableProperty<Account?> { get }

    func authenticate(with username: String, password: String)
    func logout()
}

public class AccountController: AccountControllerType {
    private static let usernameKey = "username"
    private static let passwordKey = "password"

    private let keychain = RGLockbox(withNamespace: "xyz.voltenetwork", accessibility: kSecAttrAccessibleAlways, accessGroup: "8VS9JKFDZS.com.perfectly-cooked.prototype.Volte")

    public var account = MutableProperty<Account?>(nil)

    public init() {
        print(keychain.allItems())
        rg_set_logging_severity(RGLogSeverity.trace)
        
        if let username = keychain.stringForKey(AccountController.usernameKey), let password = keychain.stringForKey(AccountController.passwordKey) {
            print("Auto-auth woooo")
            self.authenticate(with: username, password: password)
        }
    }

    public func authenticate(with username: String, password: String) {
        account.value = Account(username: username, password: password)

        keychain.setString(username, key: AccountController.usernameKey)
        keychain.setString(password, key: AccountController.passwordKey)
    }

    public func logout() {
        account.value = nil

        keychain.setString(nil, key: AccountController.usernameKey)
        keychain.setString(nil, key: AccountController.passwordKey)
    }

}
