//
//  TimelineMessageCell.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit

protocol TimelineMessageCellDelegate: class {
    func didTap(url: URL)
}

class TimelineMessageCell: UITableViewCell {
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
        label.contentInset = UIEdgeInsets(top: -4, left: -4, bottom: 0, right: 0)
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
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            contentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelineMessageCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        delegate?.didTap(url: URL)

        return false
    }
}
