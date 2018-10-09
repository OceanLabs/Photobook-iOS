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
    @IBOutlet weak var titleLabel: UILabel! { didSet { titleLabel.scaleFont() } }
    @IBOutlet weak var descriptionLabel: UILabel! { didSet { descriptionLabel.scaleFont() } }
    @IBOutlet private weak var actionButtonContainerView: UIView!
    @IBOutlet weak var primaryActionButton: UIButton! { didSet { primaryActionButton.titleLabel?.scaleFont() } }
    @IBOutlet weak var secondaryActionButton: UIButton! { didSet { secondaryActionButton.titleLabel?.scaleFont() } }
    
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
