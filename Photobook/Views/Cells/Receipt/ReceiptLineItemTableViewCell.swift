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

    @IBOutlet weak var lineItemNameLabel: UILabel!
    @IBOutlet weak var lineItemCostLabel: UILabel!
    

}
