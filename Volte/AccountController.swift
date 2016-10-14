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

struct Account {
    let username: String
    let password: String
}

protocol AccountControllerType {
    var account: MutableProperty<Account?> { get }

    func authenticate(with username: String, password: String)
}

class AccountController: AccountControllerType {
    private static let usernameKey = "username"
    private static let passwordKey = "password"

    private let keychain = RGLockbox(withNamespace: "xyz.voltenetwork") // TODO: inject this, maybe

    var account = MutableProperty<Account?>(nil)

    init() {
        if let username = keychain.stringForKey(AccountController.usernameKey), let password = keychain.stringForKey(AccountController.passwordKey) {
            print("Auto-auth woooo")
            self.authenticate(with: username, password: password)
        }
    }

    func authenticate(with username: String, password: String) {
        account.value = Account(username: username, password: password)

        keychain.setString(username, key: AccountController.usernameKey)
        keychain.setString(password, key: AccountController.passwordKey)
    }

}
