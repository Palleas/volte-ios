//
//  TimelineView.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift
import UIKit

protocol TimelineViewDelegate: class {
    func didPullToRefresh()
    func didTap(url: URL)
}

class TimelineView: UIView {
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TimelineMessageCell.self, forCellReuseIdentifier: "TimelineItemCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        
        return tableView
    }()

    private let emptyMessage: UILabel = {
        let message = UILabel()
        message.text = L10n.Timeline.Empty
        message.textColor = .black
        message.alpha = 0
        message.translatesAutoresizingMaskIntoConstraints = false

        return message
    }()

    private let refreshControl = UIRefreshControl()

    fileprivate let viewModel: TimelineViewModel

    weak var delegate: TimelineViewDelegate?

    init(viewModel: TimelineViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        backgroundColor = .white

        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        addSubview(tableView)
        addSubview(emptyMessage)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),

            emptyMessage.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyMessage.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        let messagesCount = viewModel.messages.producer.map({ $0.count })
        messagesCount.observe(on: UIScheduler()).startWithValues { [weak self] count in
            CATransaction.begin()
            CATransaction.setCompletionBlock({ 
                self?.tableView.reloadData()
            })
            self?.refreshControl.endRefreshing()
            CATransaction.commit()

            UIView.animate(withDuration: 0.3) {
                let isEmpty = count == 0
                self?.tableView.alpha = isEmpty ? 0 : 1
                self?.emptyMessage.alpha = isEmpty ? 1 : 0
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handleRefresh() {
        self.delegate?.didPullToRefresh()
    }
}

extension TimelineView: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messages = viewModel.messages.value
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineItemCell", for: indexPath) as! TimelineMessageCell
        cell.delegate = self

        cell.configure(item: messages[indexPath.row])

        let digest = messages[indexPath.row].author!.data(using: String.Encoding.utf8)!
        let avatarURL = URL(string: "https://www.gravatar.com/avatar/\(digest.md5().toHexString())?d=identicon")!

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

extension TimelineView: TimelineMessageCellDelegate {
    func didTap(url: URL) {
        delegate?.didTap(url: url)
    }
}
