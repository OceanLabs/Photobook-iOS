//
//  LayoutSelectionCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 19/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class LayoutSelectionCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(LayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    static let pageSideMargin: CGFloat = 20.0
    static let cornerRadius: CGFloat = 8.0
    static let borderWidth: CGFloat = 3.0
    static let borderInset = borderWidth * 0.5
    static let borderColor = UIColor(red: 21.0 / 255.0, green: 96.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0).cgColor
    
    private var borderLayer: CAShapeLayer!
    
    var isLayoutSelected = false {
        willSet {
            guard isLayoutSelected != newValue else { return }
            if newValue {
                layer.addSublayer(borderLayer)
            } else {
                borderLayer.removeFromSuperlayer()
            }
        }
    }
    
    // Constraints
    @IBOutlet weak var pageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageHorizontalAlignmentConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var roundedBackgroundView: UIView! {
        didSet {
            let rect = roundedBackgroundView.bounds
            let path = UIBezierPath(roundedRect: rect, cornerRadius: LayoutSelectionCollectionViewCell.cornerRadius).cgPath
            
            let maskLayer = CAShapeLayer()
            maskLayer.fillColor = UIColor.white.cgColor
            maskLayer.path = path
            maskLayer.frame = roundedBackgroundView.bounds //self.bounds
            
            roundedBackgroundView.layer.mask = maskLayer
        }
    }
    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let inset = LayoutSelectionCollectionViewCell.borderInset
        let rect = CGRect(x: 0.0, y: 0.0, width: self.bounds.maxX - inset, height: self.bounds.maxY - inset)
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: LayoutSelectionCollectionViewCell.cornerRadius).cgPath
        borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.path = borderPath
        borderLayer.frame = self.bounds
        borderLayer.strokeColor = LayoutSelectionCollectionViewCell.borderColor
        borderLayer.lineWidth = LayoutSelectionCollectionViewCell.borderWidth
    }
}

