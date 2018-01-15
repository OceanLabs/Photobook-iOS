//
//  OrderSummaryUpsellTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 08/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryUpsellTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tickImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        tickImageView.isHighlighted = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        tickImageView.isHighlighted = selected
        
    }

}
