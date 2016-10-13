//
//  SendMessageViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift

class ComposeMessageView: UIView {

    let contentField = UITextView()

    init() {
        super.init(frame: .zero)
        contentField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentField)

        NSLayoutConstraint.activate([
            contentField.topAnchor.constraint(equalTo: topAnchor),
            contentField.leftAnchor.constraint(equalTo: leftAnchor),
            contentField.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentField.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ComposeMessageViewController: UIViewController {

    private let composer: MessageComposer
    
    init(composer: MessageComposer) {
        self.composer = composer
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapSend))
        title = "Compose"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let composeMessageView = ComposeMessageView()

        self.view = composeMessageView
    }

    func didTapSend() {
        let content = (view as! ComposeMessageView).contentField.text ?? "No content"

        composer
            .sendMessage(with: content)
            .observe(on: UIScheduler())
            .startWithResult { [weak self] result in
                print("Error = \(result.error)")
                print("Value = \(result.value)")
                if let _ = result.value {
                    self?.navigationController?.popViewController(animated: true) // boo.
                }
            }
    }
}
