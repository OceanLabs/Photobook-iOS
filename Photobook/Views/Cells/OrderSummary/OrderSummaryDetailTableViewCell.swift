//
//  OrderSummaryDetailTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 10/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel? {
        didSet {
            if #available(iOS 11.0, *) {
                titleLabel?.font = UIFontMetrics.default.scaledFont(for: titleLabel!.font)
                titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var priceLabel: UILabel? {
        didSet {
            if #available(iOS 11.0, *) {
                priceLabel?.font = UIFontMetrics.default.scaledFont(for: priceLabel!.font)
                priceLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
}
