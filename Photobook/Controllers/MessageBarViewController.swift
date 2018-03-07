//
//  MessageBarViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 07/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Type of message
///
/// - info: General info for the user
/// - error: Severe error in response to a user action or server request.
/// - warning: Inform the user of critical information in the current context
enum MessageType {
    case info
    case error
    case warning
    
    func backgroundColor() -> UIColor {
        switch self {
        case .error:
            return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        case .warning:
            return UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0)
        default:
            return UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        }
    }
}

/// Manages a UI for displaying info, warning or error messages to the user
class MessageBarViewController: UIViewController {
    
    private struct Constants {
        static let animateOnScreenTime = 0.3
        static let animateOffScreenTime = 0.2
    }
    
    static let identifier = NSStringFromClass(MessageBarViewController.self).components(separatedBy: ".").last!
    
    // Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMarginContainerConstraint: NSLayoutConstraint!
    var messageViewHeightConstraint: NSLayoutConstraint?
    
    // Vars
    private var message: String!
    private var type: MessageType!
    private var dismissAfter: TimeInterval?
    private var action: (() -> ())?
    
    private var hasSetConstraints = false
    private var offsetTop: CGFloat = 0.0
    private var alignment = NSTextAlignment.left
    
    // Shared instance
    // There should only be one message displayed at any given time.
    private static var sharedController: MessageBarViewController!
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.alpha = 0
        
        containerView.layer.shadowRadius = 4.0
        containerView.layer.shadowOpacity = 0.6
        containerView.backgroundColor = type.backgroundColor()
        
        label.textColor = UIColor.white
        
        // Subscribe to notifications
        NotificationCenter.default.addObserver(self, selector: #selector(triggerActionIfNeeded), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        defer { super.viewDidLayoutSubviews() }
        
        if dismissAfter == nil && messageViewHeightConstraint == nil {
            messageViewHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: view.superview, attribute: .height, multiplier: 1.0, constant: 0.0)
            view.superview?.addConstraint(messageViewHeightConstraint!)
        } else if dismissAfter != nil && messageViewHeightConstraint != nil {
            view.superview?.removeConstraint(messageViewHeightConstraint!)
            messageViewHeightConstraint = nil
        }
        
        imageWidthConstraint.constant = imageView.image != nil ? 48.0 : 0.0
        
        guard !hasSetConstraints else { return }
        
        hasSetConstraints = true
        
        label.text = message
        label.textAlignment = alignment
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let viewDictionary : [ String : UIView ] = [ "messageView" : view ]
        let metrics = [ "offsetTop" : offsetTop ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[messageView]|", options: [], metrics: nil, views: viewDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[messageView]", options: [], metrics: metrics, views: viewDictionary)
        
        view.superview?.addConstraints(horizontalConstraints + verticalConstraints)
        view.superview?.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start off-screen
        topMarginContainerConstraint.constant = -containerView.bounds.height
        
        view.superview?.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        topMarginContainerConstraint.constant = 0.0
        
        // Animate on screen
        UIView.animate(withDuration: Constants.animateOnScreenTime, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1.0
            self.view.superview?.layoutIfNeeded()
        }, completion: { (finished) in
            guard let dismissAfter = self.dismissAfter else { return }
            
            // Set timer for auto-dismissal
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(dismissAfter)) {
                self.hide()
            }
        })
    }
    
    @IBAction private func hide() {
        topMarginContainerConstraint.constant = -containerView.bounds.height
        UIView.animate(withDuration: Constants.animateOffScreenTime, animations: {
            self.view.alpha = 0.0
            self.view.superview?.layoutIfNeeded()
        }) { (finished) in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
            
            // Run the action
            if let action = self.action {
                action()
            }
        }
    }
    
    @objc private func triggerActionIfNeeded() {
        if action != nil && dismissAfter == nil {
            hide()
            action!()
        }
    }
    
    // MARK: Public methods
    
    /// Animates a message on screen
    ///
    /// - Parameters:
    ///   - message: Text to display
    ///   - type: Type of message
    ///   - parentViewController: The viewController on whose view the message show display
    ///   - offsetTop: The Y position the message should animate from
    ///   - dismissAfter: The time after which the message should dismiss. If ignored or nil, it will stay on screen till dismissed by the user.
    ///   - centred: whether the text should be centred in the dialog
    static func show(message: String, type: MessageType, parentViewController: UIViewController, offsetTop: CGFloat? = nil, centred: Bool = false, dismissAfter: TimeInterval? = nil, action : (() -> Void)? = nil) {
        
        // Check if a message is already present
        if sharedController != nil {
            sharedController.view.removeFromSuperview()
            sharedController.removeFromParentViewController()
        }
        
        sharedController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: MessageBarViewController.identifier) as! MessageBarViewController
        sharedController.action = action
        sharedController.message = message
        sharedController.type = type
        sharedController.dismissAfter = dismissAfter
        
        if let offsetTop = offsetTop {
            sharedController.offsetTop = offsetTop
        } else if let offsetTop = parentViewController.navigationController?.navigationBar.frame.maxY {
            sharedController.offsetTop = offsetTop
        } else {
            sharedController.offsetTop = 0.0
        }
        
        sharedController.alignment = centred ? .center : .left
        
        parentViewController.view.addSubview(sharedController.view)
        
        parentViewController.addChildViewController(sharedController)
        sharedController.didMove(toParentViewController: parentViewController)
    }
    
    /// Animates the currently presented message off screen
    static func hide() {
        if let sharedController = sharedController {
            sharedController.hide()
        }
    }
}

