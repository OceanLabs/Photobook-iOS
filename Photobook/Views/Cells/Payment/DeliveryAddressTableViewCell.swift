//
//  DeliveryAddressTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryAddressTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(DeliveryAddressTableViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet private weak var separator: UIView!
    @IBOutlet weak var topLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                topLabel.font = UIFontMetrics.default.scaledFont(for: topLabel.font)
                topLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var bottomLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                bottomLabel.font = UIFontMetrics.default.scaledFont(for: bottomLabel.font)
                bottomLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var checkmark: UIImageView!
    

}
