//
//  LayoutSelectionCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 19/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class LayoutSelectionCollectionViewCell: BorderedCollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(LayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    // Constraints
    @IBOutlet weak var pageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageHorizontalAlignmentConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var roundedBackgroundView: UIView! {
        didSet {
            roundedBackgroundView.bezierRoundedCorners(withRadius: BorderedCollectionViewCell.cornerRadius)
        }
    }
    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!    
}

