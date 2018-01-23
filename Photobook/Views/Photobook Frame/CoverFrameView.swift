//
//  CoverFrameView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 12/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct CoverColors {
    struct White {
        static let color1 = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0).cgColor
        static let color2 = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.9).cgColor
        static let color3 = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 0.9).cgColor
        static let color4 = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9).cgColor
    }
    struct Black {
        static let color1 = UIColor(red: 0.21, green: 0.21, blue: 0.21, alpha: 1.0).cgColor
        static let color2 = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        static let color3 = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9).cgColor
    }
}

class CoverFrameView: UIView {
    
    @IBOutlet private weak var coverBackgroundView: CoverBackgroundView!
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageView: PhotobookPageView! {
        didSet {
            pageView.index = 0
            pageView.color = color
            pageView.productLayout = ProductManager.shared.productLayouts.first
            pageView.aspectRatio = ProductManager.shared.product!.coverSizeRatio
        }
    }
    
    var width: CGFloat! {
        didSet {
            guard let width = width else { return }
            widthConstraint.constant = width
        }
    }

    var pageSide = PageSide.left
    var color: ProductColor = .white
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
        }
        
        coverBackgroundView.color = color
    }
}

// Internal background view of a photobook cover. Please use CoverFrameView instead.
class CoverBackgroundView: UIView {
    
    private struct Constants {
        static let spineWidthRatio: CGFloat = 0.05
    }

    var color: ProductColor = .white
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use CoverFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.cornerRadius = PhotobookConstants.cornerRadius
        layer.masksToBounds = true
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let topColor, bottomColor, firstSpineColor, secondSpineColor: CGColor
        
        switch color {
        case .white:
            layer.borderWidth = PhotobookConstants.borderWidth
            layer.borderColor = CoverColors.White.color1

            topColor = CoverColors.White.color2
            bottomColor = CoverColors.White.color3
            
            firstSpineColor = CoverColors.White.color4
            secondSpineColor = CoverColors.White.color2
        case .black:
            layer.borderWidth = 0.0

            topColor = CoverColors.Black.color1
            bottomColor = CoverColors.Black.color2
            
            firstSpineColor = CoverColors.Black.color3
            secondSpineColor = CoverColors.Black.color1
        }
        
        let mainLocations: [CGFloat] = [ 0.0, 0.25, 1.0 ]
        let gradientColors = [ topColor, topColor, bottomColor ]
        
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: mainLocations)
        context.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: rect.maxX, y: rect.maxY), options: CGGradientDrawingOptions(rawValue: 0))
        
        let spineLocations: [CGFloat] = [ 0.0, 0.22, 0.3, 0.8, 0.81, 1.0 ]
        let spineGradientColors = [ firstSpineColor, secondSpineColor, secondSpineColor, firstSpineColor, firstSpineColor, secondSpineColor ]
        
        context.clip(to: CGRect(x: 0.0, y: 0.0, width: rect.maxX * Constants.spineWidthRatio, height: rect.height))
        
        // Spine gradient
        let spineGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: spineGradientColors as CFArray, locations: spineLocations)
        context.drawLinearGradient(spineGradient!, start: .zero, end: CGPoint(x: rect.maxX * Constants.spineWidthRatio, y: 0.0), options: CGGradientDrawingOptions(rawValue: 0))
    }
}
