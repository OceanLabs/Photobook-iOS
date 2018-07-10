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
    @IBOutlet weak var productDescriptionLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                productDescriptionLabel.font = UIFontMetrics.default.scaledFont(for: productDescriptionLabel.font)
                productDescriptionLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var priceLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                priceLabel.font = UIFontMetrics.default.scaledFont(for: priceLabel.font)
                priceLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var itemAmountButton: UIButton! {
        didSet {
            if #available(iOS 11.0, *) {
                itemAmountButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: itemAmountButton.titleLabel!.font)
                itemAmountButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    var productIdentifier: String?
    weak var delegate: BasketProductTableViewCellDelegate?
    
    @IBAction func amountButtonTapped(_ sender: UIButton) {
        guard let identifier = productIdentifier else {
            return
        }
        delegate?.didTapAmountButton(for: identifier)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        productImageView.image = nil
    }
    
}
