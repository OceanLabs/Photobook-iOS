//
//  ReceiptActionTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 05/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptInfoTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(ReceiptInfoTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var showingButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var hiddenButtonConstraint: NSLayoutConstraint!
    
    func setActionButtonHidden(_ hidden:Bool) {
        actionButton.isHidden = hidden
        showingButtonConstraint.priority = hidden ? .defaultLow : .defaultHigh
        hiddenButtonConstraint.priority = hidden ? .defaultHigh : .defaultLow
    }
}
