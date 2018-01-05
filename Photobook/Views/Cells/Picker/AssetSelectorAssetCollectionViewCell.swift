//
//  AssetSelectorAssetCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AssetSelectorAssetCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(AssetSelectorAssetCollectionViewCell.self).components(separatedBy: ".").last!
    
    static let cornerRadius: CGFloat = 11.0
    static let borderWidth: CGFloat = 3.0
    static let borderInset: CGFloat = 1.0
    // TEMP: Refactor common colours out into utility class
    static let borderColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
    
    @IBOutlet private weak var assetImageView: UIImageView! {
        didSet {
            assetImageView.bezierRoundedCorners(withRadius: AssetSelectorAssetCollectionViewCell.cornerRadius)
        }
    }
    @IBOutlet private weak var badgeBackgroundView: UIView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    private var borderLayer: CAShapeLayer!
    
    var assetIdentifier: String!
    var assetImage: UIImage? {
        didSet {
            self.assetImageView.image = assetImage
        }
    }
    
    var isAssetSelected = false {
        willSet {
            guard isAssetSelected != newValue else { return }
            if newValue {
                layer.addSublayer(borderLayer)
            } else {
                borderLayer.removeFromSuperlayer()
            }
        }
    }
    var timesUsed = 0 {
        didSet {
            badgeBackgroundView.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.text = String(timesUsed)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let inset = AssetSelectorAssetCollectionViewCell.borderInset
        let rect = CGRect(x: -inset, y: -inset, width: self.bounds.width + 2.0 * inset, height: self.bounds.height + 2.0 * inset)
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: AssetSelectorAssetCollectionViewCell.cornerRadius).cgPath
        borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.path = borderPath
        borderLayer.frame = self.bounds
        borderLayer.strokeColor = AssetSelectorAssetCollectionViewCell.borderColor
        borderLayer.lineWidth = AssetSelectorAssetCollectionViewCell.borderWidth
    }
}
