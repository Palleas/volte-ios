//
//  LoadingViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-19.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit

class LoadingView: UIView {
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

    init() {
        super.init(frame: .zero)

        backgroundColor = .black

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoadingViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
//        modalTransitionStyle = .crossDissolve
        transitioningDelegate = self

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = LoadingView()
    }

}

extension LoadingViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoadingPresentingViewController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeInTransition(.present)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeInTransition(.dismiss)
    }
}

class FadeInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    enum Style {
        case present
        case dismiss

        var alpha: CGFloat {
            return self == .present ? 1 : 0
        }
    }

    private let style: Style

    init(_ style: Style) {
        self.style = style
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        if style == .present {
            present(using: transitionContext)
        } else {
            dismiss(using: transitionContext)
        }
    }

    private func present(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        transitionContext.containerView.addSubview(to.view)
        to.view.frame = transitionContext.finalFrame(for: to)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            transitionContext.view(forKey: .to)?.alpha = self.style.alpha
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })

    }

    private func dismiss(using transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            transitionContext.view(forKey: .from)?.alpha = self.style.alpha
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}

class LoadingPresentingViewController: UIPresentationController {
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0

        return view
    }()

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()

        dimmingView.frame = containerView?.bounds ?? .zero
    }

    override var shouldPresentInFullscreen: Bool {
        return false
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        containerView?.insertSubview(dimmingView, at: 0)

        presentedView?.layer.masksToBounds = true
        presentedView?.layer.cornerRadius = 15

        let transitionCoordinator = presentedViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.2
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let size = CGSize(width: 75, height: 75)

        guard let containerViewSize = containerView?.frame.size else {
            return CGRect(origin: .zero, size: size)
        }

        let originX = (containerViewSize.width - size.width) / 2
        let originY = (containerViewSize.height - size.height) / 2

        return CGRect(origin: CGPoint(x: originX, y: originY), size: size)
    }
}
