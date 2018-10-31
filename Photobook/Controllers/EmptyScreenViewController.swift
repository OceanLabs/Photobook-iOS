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

struct ActionableErrorMessage: Error {
    var title: String
    var message: String
    var buttonTitle: String
    var buttonAction: () -> ()
    var dismissErrorPromptAfterAction: Bool
    
    static func withErrorMessage(_ errorMessage: ErrorMessage, buttonTitle: String = CommonLocalizedStrings.retry, dismissErrorPromptAfterAction: Bool = false, buttonAction: @escaping () -> ()) -> ActionableErrorMessage {
        let title = errorMessage.title ?? CommonLocalizedStrings.somethingWentWrongTitle
        let message = errorMessage.text!
        return ActionableErrorMessage(title: title, message: message, buttonTitle: buttonTitle, buttonAction: buttonAction, dismissErrorPromptAfterAction: dismissErrorPromptAfterAction)
    }
}

/// Controller to add as a child to present the empty state.
class EmptyScreenViewController: UIViewController {
    
    private static let imageHeight: CGFloat = 260.0
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel! { didSet { titleLabel.scaleFont() } }
    @IBOutlet private weak var textLabel: UILabel! { didSet { textLabel.scaleFont() } }
    @IBOutlet private weak var button: UIButton! { didSet { button.titleLabel?.scaleFont() } }
    @IBOutlet private weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var timer: Timer?
    private var buttonAction: (()->())?
    
    private weak var parentController: UIViewController? {
        didSet {
            if parentController != nil {
                self.view.frame = parentController!.view.bounds
            }
        }
    }
    
    /// Factory method to create an Empty Screen
    ///
    /// - Parameter parent: The parent view controller to add it to
    /// - Returns: An initialised Empty Screen
    static func emptyScreen(parent: UIViewController) -> EmptyScreenViewController {
        let emptyScreenViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "EmptyScreenViewController") as! EmptyScreenViewController
        emptyScreenViewController.parentController = parent
        return emptyScreenViewController
    }
    
    /// Factory method to create an Empty Screen from an ErrorMessage
    ///
    /// - Parameter errorMessage: Use this ErrorMessage to create a Empty Screen
    func show(_ errorMessage: ActionableErrorMessage) {
        show(message: errorMessage.message, title: errorMessage.title, buttonTitle: errorMessage.buttonTitle, buttonAction: errorMessage.buttonAction)
    }
    
    /// Shows the Empty Screen over the parent's UI
    ///
    /// - Parameters:
    ///   - title: The title to display
    ///   - message: The message to display
    ///   - image: An optional image
    ///   - activity: Whether it is a loading screen or not. Defaults to false.
    ///   - buttonTitle: The title for the button if visible
    ///   - buttonAction: Closure that should execute when the button is tapped
    func show(message: String, title: String? = nil, image: UIImage? = nil, activity: Bool = false, buttonTitle: String? = nil, buttonAction:(()->())? = nil) {
        
        guard let parentController = parentController else {
            fatalError("EmptyScreenViewController not added to parent!")
        }
        
        if parent == nil {
            parentController.view.addSubview(view)
            parentController.addChild(self)
            self.didMove(toParent: parentController)
        }
        
        imageView.image = image
        imageViewHeightConstraint.constant = image != nil ? EmptyScreenViewController.imageHeight : 0.0
        
        titleLabel.text = title != nil ? title : message // If no title is provided, use the message here
        textLabel.text = title != nil ? message : nil
        button.setTitle(buttonTitle, for: .normal)
        self.buttonAction = buttonAction
        
        if activity {
            // Hidden at the start
            showSubviews(false)
            activityIndicatorView.stopAnimating()
            
            // Don't show a loading view if the request takes less than 0.3 seconds
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
        }
        else {
            timer?.invalidate()
            showSubviews(true)
            activityIndicatorView.stopAnimating()
            button.alpha = buttonAction != nil ? 1.0 : 0.0
        }
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
                self.removeFromParent()
            })
            
            return
        }
        
        view.removeFromSuperview()
        removeFromParent()
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
    
    @IBAction func tappedButton(_ sender: UIButton) {
        buttonAction?()
    }
}
