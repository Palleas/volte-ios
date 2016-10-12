//
//  RootViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift


class RootView: UIView {
    var containedView: UIView?

    func transition(to view: UIView) {
        containedView?.removeFromSuperview()

        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)
        self.containedView = view

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor),
            view.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
    }
}

class RootViewController: UIViewController {
    private let accountController: AccountControllerType

    private var containedViewController: UIViewController?
    private var rootView: RootView {
        return view as! RootView
    }

    init(accountController: AccountControllerType) {
        self.accountController = accountController

        super.init(nibName: nil, bundle: nil)

        self.accountController.account.producer.startWithValues { account in
            if let account = account {
                let provider = TimelineContentProvider(account: account)
                let timelineViewController = TimelineViewController(provider: provider)
                self.transition(to: UINavigationController(rootViewController: timelineViewController))
            } else {
                self.transition(to: LoginViewController(accountController: self.accountController))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = RootView()

        self.view = rootView
    }

    func transition(to viewController: UIViewController) {
        containedViewController?.removeFromParentViewController()

        addChildViewController(viewController)
        rootView.transition(to: viewController.view)
        viewController.didMove(toParentViewController: self)
    }

}
