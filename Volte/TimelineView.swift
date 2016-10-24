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
    fileprivate let formater: DateFormatter = {
        let formater = DateFormatter()
        formater.dateStyle = .short
        formater.timeStyle = .none

        return formater
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TimelineMessageCell.self, forCellReuseIdentifier: "TimelineItemCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension

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
            self?.refreshControl.endRefreshing()
            self?.tableView.reloadData()

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
        refreshControl.endRefreshing()

        delegate?.didPullToRefresh()
    }


    fileprivate func format(date: Date) -> String {
        let interval = Int(Date().timeIntervalSince(date))

        if interval < 60 {
            return L10n.Timeline.Date.SecondsAgo(p0: interval)
        } else if interval < 3600 {
            return L10n.Timeline.Date.MinutesAgo(p0: Int(interval / 60))
        } else if interval < 86400 {
            return L10n.Timeline.Date.HoursAgo(p0: Int(interval / 3600))
        }
        
        return formater.string(from: date)
    }

    func attributedString(forAuthor author: String, date: Date) -> NSAttributedString {
        let string = NSMutableAttributedString(string: author, attributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSForegroundColorAttributeName: UIColor.black
        ])

        string.append(NSMutableAttributedString(string: " " + format(date: date), attributes: [
            NSFontAttributeName: UIFont.systemFont(ofSize: 13),
            NSForegroundColorAttributeName: UIColor.lightGray
        ]))

        return string
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
        cell.delegate = self

        cell.titleLabel.attributedText = attributedString(forAuthor: messages[indexPath.row].email, date: messages[indexPath.row].date)

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

extension TimelineView: TimelineMessageCellDelegate {
    func didTap(url: URL) {
        delegate?.didTap(url: url)
    }
}
