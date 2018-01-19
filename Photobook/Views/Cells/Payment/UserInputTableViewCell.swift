//
//  UserInputTableViewCell.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 18/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class UserInputTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textFieldLeadingConstraint: NSLayoutConstraint!
    var message: String? {
        didSet{
            if messageLabel.text != message{
                messageLabel.alpha = 0
                messageLabel.text = message
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.messageLabel.alpha = 1
                self.messageLabel.textColor = UIColor.black
            })
        }
    }
    var errorMessage: String? {
        didSet{
            if messageLabel.text != errorMessage{
                messageLabel.alpha = 0
                messageLabel.text = errorMessage
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.messageLabel.alpha = 1
            })
        }
    }
}
