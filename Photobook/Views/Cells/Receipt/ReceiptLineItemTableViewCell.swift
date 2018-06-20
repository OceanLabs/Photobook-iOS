//
//  ReceiptLineItemTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 30/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptLineItemTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(ReceiptLineItemTableViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var lineItemNameLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                lineItemNameLabel.font = UIFontMetrics.default.scaledFont(for: lineItemNameLabel.font)
                lineItemNameLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var lineItemCostLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                lineItemCostLabel.font = UIFontMetrics.default.scaledFont(for: lineItemCostLabel.font)
                lineItemCostLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    

}
