//
//  LoginViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit

// TODO use RAC Action
protocol LoginViewDelegate: class {
    func didAuthenticate(with username: String?, password: String?)
}

class LoginView: UIView {

    weak var delegate: LoginViewDelegate?

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        }
    }

    func didTapLogin() {
        delegate?.didAuthenticate(with: usernameField.text, password: passwordField.text)
    }
}

class LoginViewController: UIViewController {
    fileprivate let accountController: AccountControllerType

    init(accountController: AccountControllerType) {
        self.accountController = accountController

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        guard let loginView = view as? LoginView else { return }

        loginView.delegate = self
    }
}

extension LoginViewController: LoginViewDelegate {
    func didAuthenticate(with username: String?, password: String?) {
        guard let username = username, let password = password else { return }

        accountController.authenticate(with: username, password: password)
    }
}

