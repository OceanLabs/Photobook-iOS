//
//  OrderSummaryDetailTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 10/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel? { didSet { titleLabel?.scaleFont() } }
    @IBOutlet weak var priceLabel: UILabel? { didSet { priceLabel?.scaleFont() } }
}
