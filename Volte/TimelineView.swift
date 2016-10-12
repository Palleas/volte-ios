//
//  TimelineView.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit

class TimelineView: UIView {
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TimelineMessageCell.self, forCellReuseIdentifier: "TimelineItemCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension

        return tableView
    }()

    fileprivate let viewModel: TimelineViewModel

    init(viewModel: TimelineViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        tableView.dataSource = self

        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor)
        ])



        viewModel.messages.producer.startWithValues { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelineView: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messages = viewModel.messages.value
        
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
        
    }
}

extension TimelineView: UITableViewDelegate {
    
}
