//
//  ViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        guard segue.identifier == "TimelineSegue" else {
            return
        }

        guard let timeline = segue.destination as? TimelineViewController else {
            return
        }

        timeline.account = Account(username: usernameField.text ?? "", password: passwordField.text ?? "")
    }
}

