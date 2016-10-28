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
            .promoteErrors(SharingError.self)
            .attemptMap { (account) -> Result<MessageComposer, ShareViewController.SharingError> in
                if let account = account {
                    return Result(value: MessageComposer(account: account))
                }

                return Result(error: .notAuthenticated)
            }
            .flatMap(.latest, transform: { (composer) -> SignalProducer<String, ShareViewController.SharingError> in
                return self.extractMessage().map { url in
                    var content = self.contentText ?? ""
                    if let url = url {
                        content += "\n\(url)"
                    }
                    return content
                }
                .promoteErrors(ShareViewController.SharingError.self)
                .flatMap(.latest) { content -> SignalProducer<String, ShareViewController.SharingError> in
                    return composer.sendMessage(with: content).flatMapError { _ in return SignalProducer(error: SharingError.composingError) }
                }
            })
            .observe(on: UIScheduler())
            .startWithResult { [weak self] result in
                if let error = result.error, error == .notAuthenticated {
                    let alert = UIAlertController(title: L10n.Sharing.Error.Title, message: L10n.Sharing.Error.NotAuthenticated, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L10n.Alert.Dismiss, style: .default) { _ in
                        self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                    })
                    self?.present(alert, animated: true, completion: nil)
                } else if let _ = result.error {
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

    func extractMessage() -> SignalProducer<String?, NoError> {
        guard let indexItems = extensionContext?.inputItems as? [NSExtensionItem] else { return SignalProducer.empty }

        return SignalProducer { sink, _ in
            let attachments = indexItems
                .map { $0.attachments as! [NSItemProvider] }
                .flatMap { $0 }
                .filter { $0.hasItemConformingToTypeIdentifier("public.url") }

            guard let attachment = attachments.first else {
                sink.send(value: nil)
                sink.sendCompleted()
                return
            }

            attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { response, _ in
                guard let url = (response as? URL)?.absoluteString else {
                    sink.send(value: nil)
                    sink.sendCompleted()

                    return
                }

                sink.send(value: url)
                sink.sendCompleted()
            }
        }

    }

}
