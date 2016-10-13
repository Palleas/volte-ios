//
//  SendMessageViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit

class SendMessageView: UIView {

    private let contentField = UITextView()
    private let charCountView = UIView()

    init() {
        super.init(frame: .zero)
        contentField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentField)

        charCountView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(charCountView)

        NSLayoutConstraint.activate([
            contentField.topAnchor.constraint(equalTo: topAnchor),
            contentField.leftAnchor.constraint(equalTo: leftAnchor),
            contentField.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentField.rightAnchor.constraint(equalTo: rightAnchor),

            charCountView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            charCountView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SendMessageViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapSend))
        title = "Compose"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let sendMessageView = SendMessageView()

        self.view = sendMessageView
    }

    func didTapSend() {
        
    }
}
