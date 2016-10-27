//
//  ShareViewController.swift
//  Sharing
//
//  Created by Romain Pouclet on 2016-10-26.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import UIKit
import Social
import VolteCore
import ReactiveSwift
import Result

class ShareViewController: SLComposeServiceViewController {
    enum SharingError: Error {
        case notAuthenticated
        case composingError
        case invalidURL
    }
    private let accountController = AccountController()

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        accountController.account.producer
            .promoteErrors(SharingError)
            .attemptMap { (account) -> Result<MessageComposer, ShareViewController.SharingError> in
                if let account = account {
                    return Result(value: MessageComposer(account: account))
                }

                return Result(error: .notAuthenticated)
            }
            .flatMap(.latest, transform: { (composer) -> SignalProducer<String, ShareViewController.SharingError> in
                if let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
                    let attachment = item.attachments?.first as? NSItemProvider,
                    attachment.hasItemConformingToTypeIdentifier("public.url") {

                    return SignalProducer<String, ShareViewController.SharingError> { sink, _ in
                        attachment.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) in
                            if let url = (url as? URL)?.absoluteString {
                                sink.send(value: "\(self.contentText ?? "")\n\(url)")
                                sink.sendCompleted()
                            }

                            sink.send(error: .invalidURL)
                        })
                    }
                    .flatMap(.latest, transform: { (content) -> SignalProducer<String, ShareViewController.SharingError> in
                        return composer.sendMessage(with: content)
                            .flatMapError { _ in return SignalProducer(error: SharingError.composingError) }
                    })
                }

                return SignalProducer(error: .invalidURL)
            })
            .observe(on: UIScheduler())
            .startWithResult { [weak self] result in
                if let error = result.error, error == .notAuthenticated {
                    let alert = UIAlertController(title: L10n.Sharing.Error.Title, message: L10n.Sharing.Error.NotAuthenticated, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.Alert.Dismiss, style: .default) { _ in
                        self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                    })
                    self?.present(alert, animated: true, completion: nil)
                } else if let error = result.error {
                    let alert = UIAlertController(title: L10n.Sharing.Error.Title, message: L10n.Sharing.Error.Composing, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.Alert.Dismiss, style: .default) { _ in
                        self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                    })
                    self?.present(alert, animated: true, completion: nil)

                } else {
                    self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)

                }

            }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

}
