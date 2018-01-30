//
//  AddressFieldTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 24/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AddressFieldTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(AddressFieldTableViewCell.self).components(separatedBy: ".").last!
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
}
