//
//  PaymentMethodTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 18/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PaymentMethodTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(PaymentMethodTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var tickImageView: UIImageView!
    @IBOutlet private weak var methodLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                methodLabel.font = UIFontMetrics.default.scaledFont(for: methodLabel.font)
                methodLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var methodIcon: UIImageView!
    @IBOutlet weak var separator: UIView!
    
    var method: String? {
        didSet { methodLabel.text = method }
    }
    
    var icon: UIImage? {
        didSet { methodIcon.image = icon }
    }
    
    var ticked: Bool = false {
        didSet { tickImageView.alpha = ticked ? 1.0 : 0.0 }
    }
}
