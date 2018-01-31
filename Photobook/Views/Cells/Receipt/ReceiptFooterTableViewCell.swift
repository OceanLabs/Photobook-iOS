//
//  ReceiptFooterTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 30/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptFooterTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(ReceiptFooterTableViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var totalCostLabel: UILabel!
    

}
