//
//  ProgressOverlayViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 06/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ProgressOverlayViewController: UIViewController {

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var descriptionTextView: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                descriptionTextView.font = UIFontMetrics.default.scaledFont(for: descriptionTextView.font)
                descriptionTextView.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    private weak var parentController: UIViewController? {
        didSet {
            if parentController != nil {
                self.view.frame = parentController!.view.bounds
            }
        }
    }
    
    private var timer: Timer?
    
    /// Factory method to create a progress overlay
    ///
    /// - Parameter parent: The parent view controller to add it to
    /// - Returns: An initialised Empty Screen
    static func progressOverlay(parent: UIViewController) -> ProgressOverlayViewController {
        let progressOverlayViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ProgressOverlayViewController") as! ProgressOverlayViewController
        progressOverlayViewController.parentController = parent
        return progressOverlayViewController
    }
    
    /// Shows the progress overlay over the parent's UI
    ///
    /// - Parameters:
    ///   - message: The message to display
    func show(message: String) {
        
        guard let parentController = parentController else {
            fatalError("ProgressOverlayViewController not added to parent!")
        }
        
        if parent == nil {
            parentController.view.addSubview(view)
            parentController.addChildViewController(self)
            self.didMove(toParentViewController: parentController)
        }
        
        timer?.invalidate()
        
        descriptionTextView.text = message
        activityIndicatorView.startAnimating()
        
        // Don't show a loading view if the request takes less than 0.3 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    /// Hides the Empty Screen
    ///
    /// - Parameter animated: Whether the Empty Screen should fade out or not. Defaults to false.
    func hide(animated: Bool = false) {
        guard parentController != nil else { return }
        
        timer?.invalidate()
        
        if animated {
            showSubviews(false)
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 0.0
            }, completion: { _ in
                self.view.alpha = 1
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            })
            
            return
        }
        
        view.removeFromSuperview()
        removeFromParentViewController()
    }
    
    private func showSubviews(_ show: Bool) {
        for subview in view.subviews {
            subview.alpha = show ? 1.0 : 0.0
        }
    }
    
    @objc private func timerTriggered(_ timer: Timer) {
        showSubviews(true)
        activityIndicatorView.startAnimating()
    }
}
