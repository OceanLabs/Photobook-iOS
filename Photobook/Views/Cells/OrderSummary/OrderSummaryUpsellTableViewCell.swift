//
//  OrderSummaryUpsellTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 08/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryUpsellTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel! { didSet { titleLabel.scaleFont() } }
    @IBOutlet private weak var tickImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        tickImageView.isHighlighted = false
    }
    
    func setEnabled(_ enabled: Bool) {
        tickImageView.isHighlighted = enabled
    }

}
