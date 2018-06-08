//
//  AddPaymentMethodTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 31/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AddPaymentMethodTableViewCell: UITableViewCell {

    @IBOutlet private weak var addPaymentMethodButton: UIButton! {
        didSet {
            if #available(iOS 11.0, *) {
                addPaymentMethodButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: addPaymentMethodButton.titleLabel!.font)
                addPaymentMethodButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }

}
