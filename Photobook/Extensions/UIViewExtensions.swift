//
//  UIViewExtensions.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 20/06/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    /// Takes a snapshot image of the contents of the view
    ///
    /// - Returns: The snapshot image
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// Applies a rounded corner mask to the view using a bezier path
    ///
    /// - Parameter radius: The radius
    /// - Parameter rect: The rect to use
    func bezierRoundedCorners(withRadius radius: CGFloat, rect: CGRect? = nil) {
        let maskLayer = CAShapeLayer()
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.path = UIBezierPath(roundedRect: rect ?? self.bounds, cornerRadius: radius).cgPath
        maskLayer.frame = self.bounds
        
        layer.mask = maskLayer
    }
}
