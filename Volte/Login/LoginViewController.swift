//
//  LoginViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit
import VolteCore

// TODO use RAC Action
protocol LoginViewDelegate: class {
    func didAuthenticate(with username: String?, password: String?)
    func didTapPasswordManager()
}

class LoginView: UIView {

    weak var delegate: LoginViewDelegate?

    private lazy var onePasswordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "onepassword-button").withRenderingMode(.alwaysTemplate), for: .normal)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 25, height: 25))

        return button
    }()

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        }
    }

    override func awakeFromNib() {
        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            passwordField.rightView = onePasswordButton
            passwordField.rightViewMode = .always

            onePasswordButton.addTarget(self, action: #selector(didTapPasswordManager), for: .touchUpInside)
        }

        super.awakeFromNib()
    }

    func fill(with username: String?, password: String?) {
        usernameField.text = username
        passwordField.text = password
    }

    func didTapLogin() {
        delegate?.didAuthenticate(with: usernameField.text, password: passwordField.text)
    }

    func didTapPasswordManager() {
        delegate?.didTapPasswordManager()
    }
}

extension LoginView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            delegate?.didAuthenticate(with: usernameField.text, password: passwordField.text)
        }

        return true
    }
}

class LoginViewController: UIViewController {
    fileprivate let accountController: AccountControllerType

    fileprivate var loginView: LoginView {
        return view as! LoginView
    }

    init(accountController: AccountControllerType) {
        self.accountController = accountController

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        loginView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(note:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(note:)), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(note:)), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)

        super.viewWillDisappear(animated)
    }

    func keyboardWillAppear(note: Notification) {
        guard let (height, duration, animation) = Keyboard.parse(keyboardNotification: note) else { return }

        UIView.animate(withDuration: duration, delay: 0, options: animation, animations: {
            self.loginView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
        }, completion: nil)
    }

    func keyboardWillChangeFrame(note: Notification) {
        guard let (height, duration, animation) = Keyboard.parse(keyboardNotification: note) else { return }

        UIView.animate(withDuration: duration, delay: 0, options: animation, animations: {
            self.loginView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
        }, completion: nil)
    }

    func keyboardWillHide(note: Notification) {
        guard let (_, duration, animation) = Keyboard.parse(keyboardNotification: note) else { return }

        UIView.animate(withDuration: duration, delay: 0, options: animation, animations: {
            self.loginView.scrollView.contentInset = UIEdgeInsets.zero
        }, completion: nil)
    }
}

extension LoginViewController: LoginViewDelegate {
    func didAuthenticate(with username: String?, password: String?) {
        guard let username = username, let password = password else { return }

        accountController.authenticate(with: username, password: password)
    }

    func didTapPasswordManager() {
        OnePasswordExtension.shared().findLogin(forURLString: "voltenetwork.xyz", for: self, sender: nil) { login, error in
            if let error = error as? NSError {
                if error.code == Int(AppExtensionErrorCodeCancelledByUser) {
                    print("User cancelled 1password")
                    return
                }

                // TODO present error
                print("Got error = \(error)")
            }


            let username = login?[AppExtensionUsernameKey] as? String
            let password = login?[AppExtensionPasswordKey] as? String

            self.loginView.fill(with: username, password: password)

            if let username = username, let password = password {
                self.accountController.authenticate(with: username, password: password)
            }
        }
    }
}
