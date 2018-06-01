//
//  ReceiptDetailsTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 05/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptDetailsTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(ReceiptDetailsTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet weak var shippingAddressLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                shippingAddressLabel.font = UIFontMetrics.default.scaledFont(for: shippingAddressLabel.font)
                shippingAddressLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var shippingMethodLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                shippingMethodLabel.font = UIFontMetrics.default.scaledFont(for: shippingMethodLabel.font)
                shippingMethodLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var orderNumberLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                orderNumberLabel.font = UIFontMetrics.default.scaledFont(for: orderNumberLabel.font)
                orderNumberLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var shippingAddressHeaderLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                shippingAddressHeaderLabel.font = UIFontMetrics.default.scaledFont(for: shippingAddressHeaderLabel.font)
                shippingAddressHeaderLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var shippingMethodHeaderLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                shippingMethodHeaderLabel.font = UIFontMetrics.default.scaledFont(for: shippingMethodHeaderLabel.font)
                shippingMethodHeaderLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var orderNumberHeaderLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                orderNumberHeaderLabel.font = UIFontMetrics.default.scaledFont(for: orderNumberHeaderLabel.font)
                orderNumberHeaderLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
}
