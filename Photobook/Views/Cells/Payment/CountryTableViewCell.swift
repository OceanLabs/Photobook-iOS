//
//  CountryTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 31/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class CountryTableViewCell: UITableViewCell {

    @IBOutlet private weak var label: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                label.font = UIFontMetrics.default.scaledFont(for: label.font)
                label.adjustsFontForContentSizeCategory = true
            }
        }
    }
    

}
