//
//  ReceiptHeaderTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 30/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptHeaderTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(ReceiptHeaderTableViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var uploadingSpinnerImageView: UIImageView!
    @IBOutlet weak var uploadingProgressLabel: UILabel!
    @IBOutlet weak var shippingAddressLabel: UILabel!
    @IBOutlet weak var shippingMethodLabel: UILabel!
    @IBOutlet weak var orderNumberLabel: UILabel!
    
}
