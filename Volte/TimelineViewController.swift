//
//  TimelineViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit

struct Account {
    let username: String
    let password: String
}

class TimelineViewController: UIViewController {

    var account: Account?
    private let session = MCOIMAPSession()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let account = account else {
            print("No account configured :(")
            return
        }

        let session = MCOIMAPSession()
        session.hostname = "SSL0.OVH.NET"
        session.port = 993
        session.username = account.username
        session.password = account.password
        session.connectionType = .TLS

        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))

        session.fetchMessagesOperation(withFolder: "INBOX", requestKind: MCOIMAPMessagesRequestKind.Element, uids: <#T##MCOIndexSet!#>)
//        session.fetchAllFoldersOperation().start { (error, response) in
//            print("Error = \(error)")
//            print("Response = \(response)")
//        }
//        MCOIMAPFetchMessagesOperation *fetchOperation = [session fetchMessagesOperationWithFolder:folder requestKind:requestKind uids:uids];
    }
}
