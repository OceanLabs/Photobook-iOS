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

class ProgressOverlayViewController: UIViewController {

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var descriptionTextView: UILabel! { didSet { descriptionTextView.scaleFont() } }
    
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
            parentController.addChild(self)
            self.didMove(toParent: parentController)
        }
        
        timer?.invalidate()
        
        descriptionTextView.text = message
        activityIndicatorView.startAnimating()
        
        // Don't show a loading view if the request takes less than 0.3 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
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
}
