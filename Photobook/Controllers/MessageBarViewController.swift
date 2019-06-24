//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        case .info:
            return UIColor(red: 0.64, green: 0.64, blue: 0.64, alpha: 1.0)
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
    @IBOutlet private weak var label: UILabel! { didSet { label.scaleFont() } }
    @IBOutlet private weak var containerView: UIView!
    var messageViewHeightConstraint: NSLayoutConstraint?
    
    // Vars
    private var message: ErrorMessage!
    private var dismissAfter: TimeInterval?
    private var action: (() -> ())?
    
    private var hasSetConstraints = false
    private var offsetTop: CGFloat = 0.0
    private var alignment = NSTextAlignment.left
    
    // Shared instance
    // There should only be one message displayed at any given time.
    private static var sharedController: MessageBarViewController!
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.backgroundColor = message.type.backgroundColor()
        label.textColor = UIColor.white
        
        // Subscribe to notifications
        NotificationCenter.default.addObserver(self, selector: #selector(triggerActionIfNeeded), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        defer { super.viewDidLayoutSubviews() }
        
        if dismissAfter == nil && messageViewHeightConstraint == nil {
            messageViewHeightConstraint = NSLayoutConstraint(item: view!, attribute: .height, relatedBy: .equal, toItem: view.superview, attribute: .height, multiplier: 1.0, constant: 0.0)
            view.superview?.addConstraint(messageViewHeightConstraint!)
        } else if dismissAfter != nil && messageViewHeightConstraint != nil {
            view.superview?.removeConstraint(messageViewHeightConstraint!)
            messageViewHeightConstraint = nil
        }

        guard !hasSetConstraints else { return }
        hasSetConstraints = true
        
        label.text = message.text
        label.textAlignment = alignment
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let viewDictionary : [ String: UIView ] = [ "messageView" : view ]
        let metrics = [ "offsetTop": offsetTop ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[messageView]|", options: [], metrics: nil, views: viewDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(offsetTop)-[messageView]", options: [], metrics: metrics, views: viewDictionary)
        
        view.superview?.addConstraints(horizontalConstraints + verticalConstraints)
        view.superview?.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let dismissAfter = self.dismissAfter else { return }
            
        // Set timer for auto-dismissal
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(dismissAfter)) {
            self.hide()
        }
    }
    
    @IBAction private func hide() {
        UIView.animate(withDuration: Constants.animateOffScreenTime, animations: {
            self.containerView.alpha = 0.0
        }) { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()

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
    ///   - message: The message to display
    ///   - parentViewController: The viewController on whose view the message show display
    ///   - offsetTop: The Y position the message should animate from
    ///   - dismissAfter: The time after which the message should dismiss. If ignored or nil, it will stay on screen till dismissed by the user.
    ///   - centred: whether the text should be centred in the dialog
    static func show(message: ErrorMessage, parentViewController: UIViewController, offsetTop: CGFloat? = nil, centred: Bool = false, dismissAfter: TimeInterval? = nil, action : (() -> Void)? = nil) {
        // Check if a message is already present
        if sharedController != nil {
            sharedController.view.removeFromSuperview()
            sharedController.removeFromParent()
        }
        
        sharedController = (photobookMainStoryboard.instantiateViewController(withIdentifier: MessageBarViewController.identifier) as! MessageBarViewController)
        sharedController.action = action
        sharedController.message = message
        sharedController.dismissAfter = dismissAfter
        sharedController.alignment = centred ? .center : .left
        sharedController.offsetTop = offsetTop ?? 0.0
        
        parentViewController.view.addSubview(sharedController.view)
        
        parentViewController.addChild(sharedController)
        sharedController.didMove(toParent: parentViewController)
    }
    
    /// Animates the currently presented message off screen
    static func hide() {
        if let sharedController = sharedController {
            sharedController.hide()
        }
    }
}

