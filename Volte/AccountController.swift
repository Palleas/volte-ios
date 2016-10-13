//
//  AccountController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift

struct Account {
    let username: String
    let password: String
}

protocol AccountControllerType {
    var account: MutableProperty<Account?> { get }

    func authenticate(with username: String, password: String)
}

class AccountController: AccountControllerType {

    var account = MutableProperty<Account?>(nil)

    func authenticate(with username: String, password: String) {
        account.value = Account(username: username, password: password)
    }

}
