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
import CryptoSwift

class TimelineViewController: UIViewController {

    var account: Account?
    fileprivate let provider = TimelineContentProvider()
    fileprivate var messages = [Item]()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(TimelineMessageCell.self, forCellReuseIdentifier: "TimelineItemCell")
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 140
            tableView.contentInset = .zero
        }
    }

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
    }
}

extension TimelineViewController: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineItemCell", for: indexPath) as! TimelineMessageCell
        cell.contentLabel.text = messages[indexPath.row].content
        cell.authorLabel.text = messages[indexPath.row].author

        let digest = messages[indexPath.row].email.data(using: String.Encoding.utf8)!
        let avatarURL = URL(string: "https://www.gravatar.com/avatar/\(digest.md5().toHexString())")!

        URLSession.shared.dataTask(with: avatarURL) { data, _, _ in
            guard let data = data else {
                print("Unable to load avatar")
                return
            }

            DispatchQueue.main.async {
                cell.avatarView.image = UIImage(data: data)
            }
        }.resume()

        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        session.fetchMessageByUIDOperation(withFolder: "INBOX", uid: messages)
    }
}

extension TimelineViewController: UITableViewDelegate {

}
