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

/// Represents a photobook spine as seen from the side
class SpineFrameView: UIView {
    
    // TEMP
    private struct Constants {
        static let spineThickness: CGFloat = 20.0
    }
    
    @IBOutlet private weak var textLabel: UILabel! {
        didSet {
            textLabel.transform = CGAffineTransform(rotationAngle: -.pi / 2.0)
        }
    }
    @IBOutlet private weak var textLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineBackgroundView: SpineBackgroundView!
    
    var color: ProductColor = .white
    var text: String?
    var fontType: FontType = .plain
    
    var spineTextRatio: CGFloat!
    var coverHeight: CGFloat!

    override func layoutSubviews() {
        // Figure out the available width of the spine frame
        textLabelWidthConstraint.constant = bounds.height * spineTextRatio

        if !(text ?? "").isEmpty {
            let fontSize = fontType.sizeForScreenToPageRatio(bounds.height / coverHeight)
            textLabel.attributedText = fontType.attributedText(with: text!, fontSize: fontSize, fontColor: color.fontColor(), isSpineText: true)
        } else {
            textLabel.text = ""
        }
        
        layer.shadowOffset = PhotobookConstants.shadowOffset
        layer.shadowOpacity = 1.0
        layer.shadowRadius = PhotobookConstants.shadowRadius
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        setSpineColor()
    }
    
    private func setSpineColor() {
        spineBackgroundView.color = color
        switch color {
        case .white:
            layer.shadowColor = PhotobookConstants.whiteShadowColor
            textLabel.textColor = .black
        case .black:
            layer.shadowColor = PhotobookConstants.blackShadowColor
            textLabel.textColor = .white
        }
    }
    
    func resetSpineColor() {
        setSpineColor()
        spineBackgroundView.setNeedsDisplay()
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
            layer.borderWidth = 0.0
            
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
