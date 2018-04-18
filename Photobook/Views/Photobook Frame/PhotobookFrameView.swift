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
    
    static let horizontalPageToCoverMargin: CGFloat = 16.0
    static let verticalPageToCoverMargin: CGFloat = 5.0
}

private struct ColorConstants {
    struct White {
        static let color1 = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0).cgColor
        static let color2 = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        static let color3 = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        static let color4 = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).cgColor
        static let color5 = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        static let color6 = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
    }
    struct Black {
        static let color1 = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        static let color2 = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
        static let color3 = UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0).cgColor
        static let color4 = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
        static let color5 = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        static let color6 = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        static let color7 = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
    }
}

/// Graphical representation of an open photobook
class PhotobookFrameView: UIView {
    
    static let insideColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    
    @IBOutlet private weak var coverView: PhotobookFrameCoverView!
    @IBOutlet private weak var coverInsideImageView: UIImageView! { didSet { coverInsideImageView.backgroundColor = PhotobookFrameView.insideColor } }
    @IBOutlet private weak var spreadBackgroundView: PhotobookFrameSpreadBackgroundView!
    @IBOutlet private weak var leftPagesBehindView: PhotobookFramePagesBehindView? { didSet { leftPagesBehindView!.pageSide = .left } }
    @IBOutlet private weak var rightPagesBehindView: PhotobookFramePagesBehindView? { didSet { rightPagesBehindView!.pageSide = .right } }
    @IBOutlet private weak var leftPageBackgroundView: PhotobookFramePageBackgroundView! { didSet { leftPageBackgroundView.pageSide = .left } }
    @IBOutlet private weak var rightPageBackgroundView: PhotobookFramePageBackgroundView! { didSet { rightPageBackgroundView.pageSide = .right } }
    @IBOutlet private weak var pageDividerView: PhotobookFramePageDividerView!
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet private var spreadBackgroundLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var spreadBackgroundTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leftPageView: PhotobookPageView!
    @IBOutlet weak var rightPageView: PhotobookPageView!
    
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
        
    var isLeftPageVisible = true {
        didSet {
            guard isLeftPageVisible != oldValue else { return }
            leftPageBackgroundView.isHidden = !isLeftPageVisible
            leftPagesBehindView?.isHidden = !isLeftPageVisible
            leftPageView.isVisible = isLeftPageVisible
            if spreadBackgroundLeadingConstraint != nil {
                spreadBackgroundLeadingConstraint.isActive = isLeftPageVisible
            }
        }
    }
    var isRightPageVisible = true {
        didSet {
            guard isRightPageVisible != oldValue else { return }
            rightPageBackgroundView.isHidden = !isRightPageVisible
            rightPagesBehindView?.isHidden = !isRightPageVisible
            rightPageView.isVisible = isRightPageVisible
            if spreadBackgroundTrailingConstraint != nil {
                spreadBackgroundTrailingConstraint.isActive = isRightPageVisible
            }
        }
    }
    
    var width: CGFloat! {
        didSet {
            guard let width = width else { return }
            widthConstraint.constant = width
        }
    }
    
    private var hasDoneInitialSetup = false
    
    private func setup() {
        layer.shadowOpacity = 1.0
        layer.shadowOffset = PhotobookConstants.shadowOffset
        layer.shadowRadius = PhotobookConstants.shadowRadius
        layer.masksToBounds = false
    }
    
    override func layoutSubviews() {
        if !hasDoneInitialSetup {
            setup()
            hasDoneInitialSetup = true
        }
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath

        switch coverColor {
        case .white:
            layer.shadowColor = PhotobookConstants.whiteShadowColor
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
        }
        
        pageDividerView.setVisible(isLeftPageVisible && isRightPageVisible)
        setPageColor()
    }
    
    private func setPageColor() {
        coverView.color = coverColor
        spreadBackgroundView.color = pageColor
        leftPageView.color = pageColor
        leftPageView.setTextColor()
        rightPageView.color = pageColor
        rightPageView.setTextColor()
        if leftPagesBehindView != nil { leftPagesBehindView!.color = pageColor }
        if rightPagesBehindView != nil { rightPagesBehindView!.color = pageColor }
        rightPageBackgroundView.color = pageColor
        leftPageBackgroundView.color = pageColor
        pageDividerView.color = pageColor
    }
    
    func resetPageColor() {
        setPageColor()
        if leftPagesBehindView != nil { leftPagesBehindView!.setNeedsDisplay() }
        if rightPagesBehindView != nil { rightPagesBehindView!.setNeedsDisplay() }
    }
}

// Internal class representing the inside of a cover in an open photobook. Please use PhotobookFrameView instead.
class PhotobookFrameCoverView: UIView {

    var color: ProductColor = .white {
        didSet {
            switch color {
            case .white:
                layer.borderWidth = PhotobookConstants.borderWidth
                layer.borderColor = ColorConstants.White.color1
                
                backgroundColor = ColorConstants.White.color2
            case .black:
                layer.borderWidth = 0.0
                
                backgroundColor = ColorConstants.Black.color1
            }
        }
    }
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = PhotobookConstants.cornerRadius
        layer.masksToBounds = true
    }
}

enum PageSide {
    case left, right
}

/// Internal class adding the top and bottom shadow effect for a spread.
class PhotobookFrameSpreadBackgroundView: UIView {
    var color: ProductColor = .white
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.shadowRadius = 1.0
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}

// Internal class representing a stack of pages in an open photobook. Please use PhotobookFrameView instead.
class PhotobookFramePageBackgroundView: UIView {

    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
    
    var pageSide = PageSide.left
    var color: ProductColor = .white {
        didSet {
            switch color {
            case .white:
                gradientLayer.colors = [ UIColor.white.cgColor, ColorConstants.White.color4 ]
            case .black:
                gradientLayer.colors = [ ColorConstants.Black.color4.cgColor, ColorConstants.Black.color5 ]
            }
        }
    }
    
    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
    }
}

/// Internal class representing the hint of page edges behind. Please use PhotobookFrameView instead.
class PhotobookFramePagesBehindView: UIView {
    
    var pageSide = PageSide.left
    var color: ProductColor = .white
    
    override init(frame: CGRect) {
        fatalError("Not to be used programmatically. Please use PhotobookFrameView instead.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let pagesEffectColor: CGColor
        
        switch color {
        case .white:
            UIColor.white.setFill()
            pagesEffectColor = pageSide == .left ? ColorConstants.White.color1 : ColorConstants.White.color5
        case .black:
            ColorConstants.Black.color4.setFill()
            pagesEffectColor = pageSide == .left ? ColorConstants.Black.color3 : ColorConstants.Black.color6
        }
        context.fill(rect)
        
        // Pages behind
        context.setStrokeColor(pagesEffectColor)
        context.setLineWidth(0.5)
        
        var coordX: CGFloat = pageSide == .right ? 0.5 : rect.maxX - 0.5
        let step: CGFloat = (pageSide == .right ? 1.0 : -1.0) * max((rect.maxX - 1.0) / 5.0, 1.5)
        
        let numberOfLines = 5
        for _ in 0 ..< numberOfLines {
            context.move(to: CGPoint(x: coordX, y: 0.0))
            context.addLine(to: CGPoint(x: coordX, y: rect.maxY))
            
            coordX += step
        }
        
        context.strokePath()
    }
}

// Internal class representing the fold between two pages of an open photobook. Please use PhotobookFrameView instead.
class PhotobookFramePageDividerView: UIView {
    
    var color: ProductColor = .white {
        didSet {
            switch color {
            case .white:
                backgroundColor = ColorConstants.White.color6
            case .black:
                backgroundColor = ColorConstants.Black.color7
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
        alpha = visible ? 1.0 : 0.0
    }
}
