//
//  CountryTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 31/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class CountryTableViewCell: UITableViewCell {

    @IBOutlet private weak var label: UILabel! { didSet { label.scaleFont() } }
}
