//
//  BasketProductTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 05/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol BasketProductTableViewCellDelegate: class {
    func didTapAmountButton(for productIdentifier: String)
}

class BasketProductTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(BasketProductTableViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productDescriptionLabel: UILabel! { didSet { productDescriptionLabel.scaleFont() } }
    @IBOutlet weak var priceLabel: UILabel! { didSet { priceLabel.scaleFont() } }
    @IBOutlet weak var itemAmountButton: UIButton! { didSet { itemAmountButton.titleLabel?.scaleFont() } }
    
    var productIdentifier: String?
    weak var delegate: BasketProductTableViewCellDelegate?
    
    @IBAction func amountButtonTapped(_ sender: UIButton) {
        guard let identifier = productIdentifier else {
            return
        }
        delegate?.didTapAmountButton(for: identifier)
    }    
}
