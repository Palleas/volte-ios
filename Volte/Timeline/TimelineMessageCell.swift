//
//  TimelineMessageCell.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import VolteCore

protocol TimelineMessageCellDelegate: class {
    func didTap(url: URL)
}

class TimelineMessageCell: UITableViewCell {
    fileprivate let formater: DateFormatter = {
        let formater = DateFormatter()
        formater.dateStyle = .short
        formater.timeStyle = .none

        return formater
    }()

    weak var delegate: TimelineMessageCellDelegate?

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    let contentLabel: UITextView = {
        let label = UITextView()
        label.textContainerInset = .zero
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isScrollEnabled = false
        label.dataDetectorTypes = [.link]
        label.isEditable = false
        label.isUserInteractionEnabled = true
        label.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.blue]
        label.contentInset = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        label.textAlignment = .left

        return label
    }()

    let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true

        return imageView
    }()

    let preview: UIImageView = {
        let preview = UIImageView()
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.contentMode = .scaleAspectFit
        
        return preview
    }()

    private var noAttachmentsConstraints: [NSLayoutConstraint] = []
    private var attachmentsConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentLabel.delegate = self
        contentView.addSubview(contentLabel)
        contentView.addSubview(avatarView)

        separatorInset = .zero

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: -5), // There is Probably something better to do with baseline
            titleLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 10),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor,  constant: -10),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            contentLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            contentLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            contentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18)
        ])

        noAttachmentsConstraints = [
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ]

        attachmentsConstraints = [
            preview.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 10),
            preview.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
            preview.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            preview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            preview.heightAnchor.constraint(equalToConstant: 300)
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: Message) {
        if item.attachments?.count == 0 {
            preview.removeFromSuperview()
            NSLayoutConstraint.activate(noAttachmentsConstraints)
            NSLayoutConstraint.deactivate(attachmentsConstraints)
        } else {
            contentView.addSubview(preview)
            NSLayoutConstraint.activate(attachmentsConstraints)
            NSLayoutConstraint.deactivate(noAttachmentsConstraints)

            if let attachment = item.attachments?.anyObject() as? Attachment, let data = attachment.data {
                preview.image = UIImage(data: data as Data)
            }
        }

        contentLabel.text = item.content
        titleLabel.attributedText = attributedString(forAuthor: item.author!, date: item.postedAt as! Date)

        setNeedsUpdateConstraints()
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

extension TimelineMessageCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        delegate?.didTap(url: URL)

        return false
    }
}
