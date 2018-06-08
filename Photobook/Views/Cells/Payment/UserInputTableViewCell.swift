//
//  UserInputTableViewCell.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 18/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
    @IBOutlet weak var label: UILabel? {
        didSet {
            if #available(iOS 11.0, *) {
                label?.font = UIFontMetrics.default.scaledFont(for: label!.font)
                label?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var button: UIButton? {
        didSet {
            if #available(iOS 11.0, *) {
                button?.titleLabel?.font = UIFontMetrics.default.scaledFont(for: button!.titleLabel!.font)
                button?.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var textField: UITextField! {
        didSet {
            if #available(iOS 11.0, *), let font = textField.font {
                textField.font = UIFontMetrics.default.scaledFont(for: font)
                textField.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var separator: UIView!
    @IBOutlet private weak var messageLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                messageLabel.font = UIFontMetrics.default.scaledFont(for: messageLabel.font)
                messageLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
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
