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

class UserInputTableViewCell: UITableViewCell {
    
    private struct Constants {
        static let messageColor = UIColor(red:0.43, green:0.43, blue:0.45, alpha:1)
        static let messageTopMargin: CGFloat = 6.0
        static let messageBottomMargin: CGFloat = 17.0
    }

    @IBOutlet private weak var messageTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var separatorLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet private weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel? { didSet { label?.scaleFont() } }
    @IBOutlet private weak var button: UIButton? { didSet { button?.titleLabel?.scaleFont() } }
    @IBOutlet weak var textField: UITextField! { didSet { textField.scaleFont() } }
    @IBOutlet private weak var separator: UIView!
    @IBOutlet private weak var messageLabel: UILabel! { didSet { messageLabel.scaleFont() } }
    @IBOutlet weak var textFieldLeadingConstraint: NSLayoutConstraint!
    var message: String? {
        didSet{
            if messageLabel.text != message{
                messageLabel.alpha = 0
                messageLabel.text = message
                messageLabel.textAlignment = .left
            }
            
            guard message != nil else {
                messageBottomConstraint.constant = 0
                messageTopConstraint?.constant = 0
                return
            }
            
            messageBottomConstraint.constant = Constants.messageBottomMargin
            messageTopConstraint?.constant = Constants.messageTopMargin
            
            UIView.animate(withDuration: 0.3, animations: {
                self.messageLabel.alpha = 1
                self.messageLabel.textColor = Constants.messageColor
            })
        }
    }
    var errorMessage: String? {
        didSet{
            if messageLabel.text != errorMessage{
                messageLabel.alpha = 0
                messageLabel.text = errorMessage
                messageLabel.textAlignment = .right
            }
            messageLabel.alpha = 1
            messageLabel.textColor = FormConstants.errorColor
            
            guard errorMessage != nil else {
                messageBottomConstraint.constant = 0
                messageTopConstraint?.constant = 0
                return
            }
            
            messageBottomConstraint.constant = Constants.messageBottomMargin
            messageTopConstraint?.constant = Constants.messageTopMargin
        }
    }
}
