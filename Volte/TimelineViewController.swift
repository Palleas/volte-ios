//
//  TimelineViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift

class TimelineViewController: UIViewController {

    var account: Account?
    fileprivate let provider = TimelineContentProvider()
    fileprivate var messages = [Item]()

    @IBOutlet weak var tableView: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let account = account else {
            print("No account configured :(")
            return
        }

        provider
            .authenticate(with: account)
            .fetchItems()
            .collect()
            .observe(on: UIScheduler())
            .startWithResult { [weak self] (result) in
                if let messages = result.value {
                    self?.messages = messages
                    self?.tableView.reloadData()
                } else if let error = result.error {
                    // TODO: Present error
                    print("Error = \(error)")
                }
            }



//        session.hostname = "SSL0.OVH.NET"
//        session.port = 993
//        session.username = account.username
//        session.password = account.password
//        session.connectionType = .TLS
//
//        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
//        let operation = session.fetchMessagesOperation(withFolder: "INBOX", requestKind: .headers, uids: uids)
//        operation?.start({ [weak self] (error, messages, vanishedMessages) in
//            guard let messages = messages else { return }
//            self?.messages = messages as! [MCOIMAPMessage]
//            self?.tableView.reloadData()
//        })
    }
}

extension TimelineViewController: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineItemCell", for: indexPath)
        cell.textLabel?.text = messages[indexPath.row].content
        
        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        session.fetchMessageByUIDOperation(withFolder: "INBOX", uid: messages)
    }
}

extension TimelineViewController: UITableViewDelegate {

}
