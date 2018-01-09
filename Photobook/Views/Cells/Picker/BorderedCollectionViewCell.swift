//
//  BorderedCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// A collectionView cell that can have rounded border around it
class BorderedCollectionViewCell: UICollectionViewCell {
    
    static let cornerRadius: CGFloat = 11.0
    static let borderWidth: CGFloat = 3.0
    static let borderInset: CGFloat = 1.0
    static let borderColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
    
    private var borderLayer: CAShapeLayer!
    
    var isBorderVisible = false {
        willSet {
            guard isBorderVisible != newValue else { return }
            if newValue {
                layer.addSublayer(borderLayer)
            } else {
                borderLayer.removeFromSuperlayer()
            }
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
        guard borderLayer == nil else { return }
        clipsToBounds = false
        
        let inset = AssetSelectorAssetCollectionViewCell.borderInset
        let rect = CGRect(x: -inset, y: -inset, width: self.bounds.width + 2.0 * inset, height: self.bounds.height + 2.0 * inset)
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: BorderedCollectionViewCell.cornerRadius).cgPath
        borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.path = borderPath
        borderLayer.frame = bounds
        borderLayer.strokeColor = BorderedCollectionViewCell.borderColor
        borderLayer.lineWidth = BorderedCollectionViewCell.borderWidth
    }
    
}
