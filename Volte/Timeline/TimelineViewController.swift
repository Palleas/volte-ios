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
import SafariServices
import VolteCore

protocol TimelineViewModelType {
    var messages: MutableProperty<[Item]> { get }
}

class TimelineViewModel {
    var messages = MutableProperty<[Message]>([])
}

class TimelineViewController: UIViewController {
    fileprivate let provider: TimelineContentProvider

    private let viewModel = TimelineViewModel()
    private let accountController: AccountControllerType
    fileprivate let account: Account

    init(provider: TimelineContentProvider, accountController: AccountControllerType, account: Account) {
        self.provider = provider
        self.accountController = accountController
        self.account = account

        super.init(nibName: nil, bundle: nil)
        navigationItem.titleView = {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "volte-logo-2"))
            imageView.frame = CGRect(origin: .zero, size: CGSize(width: 44, height: 44))
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapCompose))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(didTapMenu))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let timelineView = TimelineView(viewModel: viewModel)
        timelineView.delegate = self

        self.view = timelineView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setTitleVerticalPositionAdjustment(-3, for: .default)

        // 🙈
        if let presented = presentedViewController, presented is SFSafariViewController {
            return
        }

        fetchMessages()
    }

    func fetchMessages() {
        present(LoadingViewController(), animated: true, completion: nil)

        provider
            .fetchMessages()
            .observe(on: UIScheduler())
            .startWithResult { [weak self] (result) in
                self?.dismiss(animated: true, completion: nil)
                
                if let messages = result.value {
                    // TODO use RAC binding but I don't remember how it works
                    self?.viewModel.messages.value = messages
                } else if let error = result.error {
                    print("Error = \(error)")
                }
        }
    }

    func didTapCompose() {
        let composer = MessageComposer(account: account)
        let viewController = ComposeMessageViewController(composer: composer)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func didTapMenu() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.accountController.logout()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
}

extension TimelineViewController: TimelineViewDelegate {
    func didPullToRefresh() {
        fetchMessages()
    }

    func didTap(url: URL) {
        let browser = SFSafariViewController(url: url)
        present(browser, animated: true, completion: nil)
    }
}
