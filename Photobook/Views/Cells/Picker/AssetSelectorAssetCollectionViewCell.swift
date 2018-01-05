//
//  AssetSelectorAssetCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AssetSelectorAssetCollectionViewCell: BorderedCollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(AssetSelectorAssetCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var assetImageView: UIImageView! {
        didSet {
            assetImageView.bezierRoundedCorners(withRadius: BorderedCollectionViewCell.cornerRadius)
        }
    }
    @IBOutlet private weak var badgeBackgroundView: UIView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    var assetIdentifier: String!
    var assetImage: UIImage? {
        didSet {
            self.assetImageView.image = assetImage
        }
    }
    
    var timesUsed = 0 {
        didSet {
            badgeBackgroundView.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.text = String(timesUsed)
        }
    }
}
