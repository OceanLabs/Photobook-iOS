//
//  BorderedViewProtocol.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Protocol a view can conform to in order to become a rounded cornered view with a border.
protocol BorderedViewProtocol: AnyObject  {
    /// The layer drawing the border
    var borderLayer: CAShapeLayer! { get set }

    /// Background subview the rounded corners will be applied to
    var roundedBackgroundView: UIView! { get set }

    /// Whether the border should display or not
    var isBorderVisible: Bool { get set }

    /// Color of the border. Defaults to the app's blue: RGBA(0.0, 0.48, 1.0, 1.0)
    var roundedBorderColor: UIColor? { get set }

    /// Width of the border. Defaults to 1.0.
    var roundedBorderWidth: CGFloat? { get set }

    /// Radius of the view's corner and border. Defaults to half the width of the view (circle)
    var roundedCornerRadius: CGFloat? { get set }
    
    /// Colour of the background view
    var color: UIColor! { get set }
}

extension BorderedViewProtocol where Self: UIView {
    func radius() -> CGFloat {
        return roundedCornerRadius ?? bounds.maxX * 0.5 // Draw circle if nil
    }
    
    func setup(reset: Bool = false) {
        guard reset || borderLayer == nil else { return }
        
        let bWidth = roundedBorderWidth ?? 1.0
        let inset: CGFloat = bWidth * 0.5 - 0.5 // Bring the border in by 0.5 to account for the difference in the curvature of the bezier paths
        let rect = CGRect(x: -inset, y: -inset, width: bounds.width + 2.0 * inset, height: bounds.height + 2.0 * inset)
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: radius()).cgPath
        if borderLayer == nil { borderLayer = CAShapeLayer() }
        borderLayer.fillColor = nil
        borderLayer.path = borderPath
        borderLayer.frame = bounds
        borderLayer.strokeColor = roundedBorderColor != nil ? roundedBorderColor!.cgColor : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
        borderLayer.lineWidth = bWidth

        if reset { setupRoundedBackgroundView() }
    }
    
    func setupRoundedBackgroundView() {
        guard roundedBackgroundView != nil else { return }
        roundedBackgroundView.bezierRoundedCorners(withRadius: radius(), rect: bounds)
        roundedBackgroundView.backgroundColor = color
    }
    
    func setBorderVisible(_ newValue: Bool) {
        guard isBorderVisible != newValue else { return }
        if newValue {
            layer.addSublayer(borderLayer)
        } else {
            borderLayer.removeFromSuperlayer()
        }
    }
}
