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
    
    @IBOutlet weak var iconLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                iconLabel.font = UIFontMetrics.default.scaledFont(for: iconLabel.font)
                iconLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                titleLabel.font = UIFontMetrics.default.scaledFont(for: titleLabel.font)
                titleLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                descriptionLabel.font = UIFontMetrics.default.scaledFont(for: descriptionLabel.font)
                descriptionLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var actionButtonContainerView: UIView!
    @IBOutlet weak var primaryActionButton: UIButton! {
        didSet {
            if #available(iOS 11.0, *) {
                primaryActionButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: primaryActionButton.titleLabel!.font)
                primaryActionButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet weak var secondaryActionButton: UIButton! {
        didSet {
            if #available(iOS 11.0, *) {
                secondaryActionButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: secondaryActionButton.titleLabel!.font)
                secondaryActionButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    @IBOutlet private weak var showActionButtonsConstraint: NSLayoutConstraint!
    @IBOutlet private weak var hideActionButtonsConstraint: NSLayoutConstraint!
    @IBOutlet private weak var showSecondaryActionButtonConstraint: NSLayoutConstraint!
    @IBOutlet private weak var hideSecondaryActionButtonConstraint: NSLayoutConstraint!
    
    func setSecondaryActionButtonHidden(_ hidden:Bool) {
        secondaryActionButton.isHidden = hidden
        showSecondaryActionButtonConstraint.priority = hidden ? .defaultLow : .defaultHigh
        hideSecondaryActionButtonConstraint.priority = hidden ? .defaultHigh : .defaultLow
    }
    
    func setActionButtonsHidden(_ hidden:Bool) {
        actionButtonContainerView.isHidden = hidden
        showActionButtonsConstraint.priority = hidden ? .defaultLow : .defaultHigh
        hideActionButtonsConstraint.priority = hidden ? .defaultHigh : .defaultLow
    }
}
