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
    
    @IBOutlet weak var shippingAddressLabel: UILabel!
    @IBOutlet weak var shippingMethodLabel: UILabel!
    @IBOutlet weak var orderNumberLabel: UILabel!

}
