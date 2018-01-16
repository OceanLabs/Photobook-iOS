//
//  SpineFrameView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Represents a photobook spine as seen from the side
class SpineFrameView: UIView {
    
    static let spineTextPadding: CGFloat = 5.0
    
    @IBOutlet private weak var textLabel: UILabel! { didSet { textLabel.transform = CGAffineTransform(rotationAngle: -.pi / 2.0) } }
    @IBOutlet private weak var textLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineBackgroundView: SpineBackgroundView!
    
    var pageSide = PageSide.left
    var color: ProductColor = .white
    var spineText: String? { didSet { textLabel.text = spineText } }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        spineBackgroundView.color = color
        textLabelWidthConstraint.constant = bounds.height - 2.0 * SpineFrameView.spineTextPadding
        
        layer.shadowOffset = PhotobookConstants.shadowOffset
        layer.shadowOpacity = 1.0
        layer.shadowRadius = PhotobookConstants.shadowRadius
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        switch color {
        case .white:
            layer.shadowColor = PhotobookConstants.whiteShadowColor
            textLabel.textColor = .black
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
            textLabel.textColor = .white
        }
    }
}

// Internal background view of a spine. Please use SpineFrameView instead.
class SpineBackgroundView: UIView {
    
    var color: ProductColor = .white
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use SpineFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        layer.cornerRadius = PhotobookConstants.cornerRadius
        layer.masksToBounds = true
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let firstSpineColor, secondSpineColor: CGColor
        
        switch color {
        case .white:
            layer.borderWidth = PhotobookConstants.borderWidth
            layer.borderColor = CoverColors.White.color1
            
            firstSpineColor = CoverColors.White.color4
            secondSpineColor = CoverColors.White.color2
        case .black:
            firstSpineColor = CoverColors.Black.color3
            secondSpineColor = CoverColors.Black.color1
        }
        
        
        let spineLocations: [CGFloat] = [ 0.0, 0.25, 0.75, 1.0 ]
        let spineGradientColors = [ firstSpineColor, secondSpineColor, secondSpineColor, firstSpineColor ]
        
        // Spine gradient
        let spineGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: spineGradientColors as CFArray, locations: spineLocations)
        context.drawLinearGradient(spineGradient!, start: .zero, end: CGPoint(x: rect.maxX, y: 0.0), options: CGGradientDrawingOptions(rawValue: 0))
    }
}
