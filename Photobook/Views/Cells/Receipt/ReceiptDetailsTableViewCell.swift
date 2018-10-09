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
    
    @IBOutlet weak var shippingAddressLabel: UILabel! { didSet { shippingAddressLabel.scaleFont() } }
    @IBOutlet weak var shippingMethodLabel: UILabel! { didSet { shippingMethodLabel.scaleFont() } }
    @IBOutlet weak var orderNumberLabel: UILabel! { didSet { orderNumberLabel.scaleFont() } }
    @IBOutlet private weak var shippingAddressHeaderLabel: UILabel! { didSet { shippingAddressHeaderLabel.scaleFont() } }
    @IBOutlet private weak var shippingMethodHeaderLabel: UILabel! { didSet { shippingMethodHeaderLabel.scaleFont() } }
    @IBOutlet private weak var orderNumberHeaderLabel: UILabel! { didSet { orderNumberHeaderLabel.scaleFont() } }
}
