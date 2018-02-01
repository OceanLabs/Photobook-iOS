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
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!
    

}
