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
import VolteCore


protocol ComposeMessageViewDelegate: class {
    func didTapCamera()
}

class ComposeMessageView: UIView {

    let contentField: UITextView = {
        let field = UITextView()
        field.font = .systemFont(ofSize: 18)
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    let placeholder: UILabel = {
        let placeholder = UILabel()
        placeholder.text = L10n.Timeline.Compose.WhatAreYouUpTo
        placeholder.textColor = .lightGray
        placeholder.font = .systemFont(ofSize: 18)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.isUserInteractionEnabled = false

        return placeholder
    }()

    let previewView: UIImageView = {
        let preview = UIImageView()
        preview.translatesAutoresizingMaskIntoConstraints = false

        return preview
    }()

    private let toolbar = UIToolbar()

    let preview = MutableProperty<UIImage?>(nil)

    weak var delegate: ComposeMessageViewDelegate?

    init() {
        super.init(frame: .zero)
        contentField.delegate = self
        addSubview(contentField)
        addSubview(placeholder)
        addSubview(previewView)

        NSLayoutConstraint.activate([
            contentField.topAnchor.constraint(equalTo: topAnchor),
            contentField.leftAnchor.constraint(equalTo: leftAnchor),
            contentField.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentField.rightAnchor.constraint(equalTo: rightAnchor),

            placeholder.topAnchor.constraint(equalTo: topAnchor, constant: 71), // SORRY 🙈
            placeholder.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),

            previewView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            previewView.widthAnchor.constraint(equalToConstant: 100),
            previewView.heightAnchor.constraint(equalToConstant: 100)
        ])

        preview.producer.startWithValues { self.previewView.image = $0 }

        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(didTapCamera))
        ]
        contentField.inputAccessoryView = toolbar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapCamera() {
        delegate?.didTapCamera()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        toolbar.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: 44))
    }
}

extension ComposeMessageView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        UIView.animate(withDuration: 0.1) {
            self.placeholder.alpha = textView.text.isEmpty ? 1 : 0
        }
    }
}

class ComposeMessageViewController: UIViewController {

    private let composer: MessageComposer
    fileprivate var attachment = MutableProperty<Data?>(nil)
    private var composeMessageView: ComposeMessageView {
        return view as! ComposeMessageView
    }

    init(composer: MessageComposer) {
        self.composer = composer
        
        super.init(nibName: nil, bundle: nil)

        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapSend))

        title = L10n.Timeline.Compose.Title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let composeMessageView = ComposeMessageView()
        composeMessageView.delegate = self
        self.view = composeMessageView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        composeMessageView.preview <~ attachment.producer.map { $0.flatMap(UIImage.init) }

    }

    func didTapSend() {
        present(LoadingViewController(), animated: true, completion: nil)
        let content = (view as! ComposeMessageView).contentField.text ?? "No content"

        composer
            .sendMessage(with: content, attachments: [attachment.value].flatMap { $0 })
            .observe(on: UIScheduler())
            .on(completed: { [weak self] in
                self?.dismiss(animated: true) {
                    _ = self?.navigationController?.popViewController(animated: true) // boo.
                }
            })
            .startWithFailed({ [weak self] error in
                let alert = UIAlertController(title: L10n.Compose.Error.Title, message: L10n.Compose.Error.Message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.Alert.Dismiss, style: .default) { [weak self] _ in
                    self?.dismiss(animated: true, completion: nil)
                })

                self?.dismiss(animated: true) {
                    self?.present(alert, animated: true, completion: nil)
                }
            })
    }
}

extension ComposeMessageViewController: ComposeMessageViewDelegate {
    func didTapCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true

        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension ComposeMessageViewController: UINavigationControllerDelegate {}

extension ComposeMessageViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }

        let size = CGSize(width: 612, height: 612)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 612, height: 612), true, 0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        self.attachment.value = UIImageJPEGRepresentation(resized, 75)!
        dismiss(animated: true, completion: nil)
    }
}
