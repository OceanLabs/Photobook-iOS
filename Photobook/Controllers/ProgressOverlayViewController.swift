//
//  ProgressOverlayViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 06/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ProgressOverlayViewController: UIViewController {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var descriptionTextView: UILabel!
    
    private weak var parentController: UIViewController? {
        didSet {
            if parentController != nil {
                self.view.frame = parentController!.view.bounds
            }
        }
    }
    
    /// Factory method to create a progress overlay
    ///
    /// - Parameter parent: The parent view controller to add it to
    /// - Returns: An initialised Empty Screen
    static func progressOverlay(parent: UIViewController) -> ProgressOverlayViewController {
        let progressOverlayViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProgressOverlayViewController") as! ProgressOverlayViewController
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
        
        self.view.alpha = 1.0
        descriptionTextView.text = message
        activityIndicatorView.startAnimating()
    }
    
    /// Hides the Empty Screen
    ///
    /// - Parameter animated: Whether the Empty Screen should fade out or not. Defaults to false.
    func hide(animated: Bool = false) {
        guard parentController != nil else { return }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 0.0
            }, completion: { (finished) in
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            })
        } else {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }
}
