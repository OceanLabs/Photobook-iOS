//
//  AddressFieldTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 24/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AddressFieldTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(AddressFieldTableViewCell.self).components(separatedBy: ".").last!
    
    
    @IBOutlet weak var label: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                label.font = UIFontMetrics.default.scaledFont(for: label.font)
                label.adjustsFontForContentSizeCategory = true
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
    
}
