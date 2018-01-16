//
//  PhotobookFrameView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 11/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct PhotobookConstants {
    static let whiteShadowColor = UIColor(white: 0.4, alpha: 0.2).cgColor
    static let blackShadowColor = UIColor(white: 0.0, alpha: 0.5).cgColor // Apply a stronger shadow for black photobooks. Otherwise it is not noticeable.
    static let shadowOffset = CGSize(width: 0.0, height: 3.0)
    static let shadowRadius: CGFloat = 4.0
    static let cornerRadius: CGFloat = 1.0
    static let borderWidth: CGFloat = 0.5
}

/// Graphical representation of an open photobook
class PhotobookFrameView: UIView {
    
    static let insideColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    
    @IBOutlet private weak var coverView: PhotobookFrameCoverView!
    @IBOutlet private weak var coverInsideImageView: UIImageView! { didSet { coverInsideImageView.backgroundColor = PhotobookFrameView.insideColor } }
    @IBOutlet private weak var leftPageBackgroundView: PhotobookFramePageBackgroundView! { didSet { leftPageBackgroundView.pageSide = .left } }
    @IBOutlet private weak var rightPageBackgroundView: PhotobookFramePageBackgroundView! { didSet { rightPageBackgroundView.pageSide = .right } }
    @IBOutlet private weak var pageDividerView: PhotobookFramePageDividerView!
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leftPageView: PhotobookPageView!
    @IBOutlet weak var rightPageView: PhotobookPageView!
    
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    
    var isLeftPageVisible = true { didSet { leftPageBackgroundView.isHidden = !isLeftPageVisible } }
    var isRightPageVisible = true { didSet { rightPageBackgroundView.isHidden = !isRightPageVisible } }
    
    var width: CGFloat! {
        didSet {
            guard let width = width else { return }
            widthConstraint.constant = width
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowOffset = PhotobookConstants.shadowOffset
        layer.shadowOpacity = 1.0
        layer.shadowRadius = PhotobookConstants.shadowRadius
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        switch coverColor {
        case .white:
            layer.shadowColor = PhotobookConstants.whiteShadowColor
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
        }
        
        coverView.color = coverColor
        leftPageBackgroundView.color = pageColor
        rightPageBackgroundView.color = pageColor
        pageDividerView.setVisible(isLeftPageVisible && isRightPageVisible)
        pageDividerView.color = pageColor
    }
}

// Internal class representing the inside of a cover in an open photobook. Please user PhotobookFrameView instead.
class PhotobookFrameCoverView: UIView {

    var color: ProductColor = .white
    
    private struct Constants {
        struct White {
            static let color1 = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0).cgColor
            static let color2 = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        }
        struct Black {
            static let color1 = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
            static let color2 = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
        }
    }
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
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
        
        let shineColor: CGColor
        
        switch color {
        case .white:
            layer.borderWidth = PhotobookConstants.borderWidth
            layer.borderColor = Constants.White.color1

            Constants.White.color2.setFill()
            shineColor = UIColor.white.cgColor
        case .black:
            layer.borderWidth = 0.0
            
            Constants.Black.color1.setFill()
            shineColor = Constants.Black.color2
        }
        context.fill(rect)
        
        // Left shine effect
        context.setStrokeColor(shineColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 1.5, y: 0.0))
        context.addLine(to: CGPoint(x: 1.5, y: rect.maxY))
        context.strokePath()
    }
}

enum PageSide {
    case left, right
}

// Internal class representing a stack of pages in an open photobook. Please user PhotobookFrameView instead.
class PhotobookFramePageBackgroundView: UIView {

    var pageSide = PageSide.left
    var color: ProductColor = .white
    
    private struct Constants {
        struct White {
            static let color1 = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
            static let color2 = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0).cgColor
            static let color3 = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        }
        struct Black {
            static let color1 = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
            static let color2 = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
            static let color3 = UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0).cgColor
            static let color4 = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        }
    }
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let gradientColors: [CGColor]
        let pagesEffectColor: CGColor
        let topLineColor: CGColor
        
        switch color {
        case .white:
            UIColor.white.setFill()
            
            gradientColors = [ UIColor.white.cgColor, UIColor.white.cgColor, UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).cgColor ]
            
            topLineColor = Constants.White.color1
            pagesEffectColor = pageSide == .left ? Constants.White.color2 : Constants.White.color3
        case .black:
            Constants.Black.color1.setFill()
            
            gradientColors = [ Constants.Black.color1.cgColor, Constants.Black.color1.cgColor, Constants.Black.color2 ]

            topLineColor = Constants.Black.color3
            pagesEffectColor = pageSide == .left ? Constants.Black.color3 : Constants.Black.color4
        }
        context.fill(rect)
        
        // Gradient
        let coordX: CGFloat! = pageSide == .left ? 0.0 : rect.maxX - 7.0
        
        let locations: [CGFloat] = [ 0.0, 0.5, 1.0 ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: locations)
        context.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: rect.maxX, y: 0.0), options: CGGradientDrawingOptions(rawValue: 0))
        
        // Top line
        context.setStrokeColor(topLineColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 0.0, y: 0.0))
        context.addLine(to: CGPoint(x: rect.maxX, y: 0.0))
        context.strokePath()
        
        // Pages behind
        context.setStrokeColor(pagesEffectColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: coordX + 0.5, y: 0.0))
        context.addLine(to: CGPoint(x: coordX + 0.5, y: rect.maxY))
        context.move(to: CGPoint(x: coordX + 2.5, y: 0.0))
        context.addLine(to: CGPoint(x: coordX + 2.5, y: rect.maxY))
        context.move(to: CGPoint(x: coordX + 4.5, y: 0.0))
        context.addLine(to: CGPoint(x: coordX + 4.5, y: rect.maxY))
        context.move(to: CGPoint(x: coordX + 6.5, y: 0.0))
        context.addLine(to: CGPoint(x: coordX + 6.5, y: rect.maxY))
        context.strokePath()
    }
    
    override func layoutSubviews() {
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 1.0
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        super.layoutSubviews()
    }
}

// Internal class representing the fold between two pages of an open photobook. Please user PhotobookFrameView instead.
class PhotobookFramePageDividerView: UIView {
 
    private struct Constants {
        static let white = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
        static let black = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
    }

    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    
    var color: ProductColor = .white {
        didSet {
            switch color {
            case .white:
                backgroundColor = Constants.white
            case .black:
                backgroundColor = Constants.black
            }
        }
    }
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Sets whether the divider should be visible or not. If not, the width is zeroed as well.
    ///
    /// - Parameter visible: Shows the divider if true, hides it otherwise
    func setVisible(_ visible: Bool) {
        widthConstraint.constant = visible ? 1.0 : 0.0
    }
}
