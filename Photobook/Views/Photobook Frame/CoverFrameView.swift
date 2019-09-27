//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    @IBOutlet weak var pageView: PhotobookPageView!
    
    var width: CGFloat! {
        didSet {
            guard let width = width else { return }
            widthConstraint.constant = width
        }
    }
    
    var pageSide = PageSide.left
    var color: ProductColor = .white
    var aspectRatio: CGFloat!
    var product: PhotobookProduct! {
        didSet { pageView.product = product }
    }
    
    override func layoutSubviews() {
        layer.shadowOffset = PhotobookConstants.shadowOffset
        layer.shadowOpacity = 1.0
        layer.shadowRadius = PhotobookConstants.shadowRadius
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        setCoverColor()
    }
    
    private func setCoverColor() {
        switch color {
        case .white:
            layer.shadowColor = PhotobookConstants.whiteShadowColor
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
        }

        pageView.color = color
        pageView.aspectRatio = aspectRatio
        coverBackgroundView.color = color
    }
    
    func resetCoverColor() {
        setCoverColor()
        pageView.setTextColor()
        coverBackgroundView.setNeedsDisplay()
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
