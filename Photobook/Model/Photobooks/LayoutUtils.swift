//
//  LayoutUtils.swift
//  Photobook
//
//  Created by Jaime Landazuri on 30/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

/// Utilities class that handles adjustments to a view in a container
class LayoutUtils {

    /// Amends a transform that will scale and nudge a View to fill a Container from its current transform
    /// IMPORTANT: It assumes that the View would be centred in the Container if the transform were the identity.
    ///
    /// - Parameters:
    ///   - transform: The current transform
    ///   - viewSize: The size of the View to fill the Container
    ///   - containerSize: The size of the Container
    /// - Returns: A new adjusted transform where the Container will be completely filled by the View
    static func adjustTransform(_ transform: CGAffineTransform, forViewSize viewSize: CGSize, inContainerSize containerSize: CGSize) -> CGAffineTransform {
        let angle = atan2(transform.b, transform.a)
        var scale = sqrt(transform.a * transform.a + transform.c * transform.c)
        
        // Check the minimum scale factor to fill the container taking into consideration the view's current rotation
        let minScaleFactor = scaleFactorToFill(containerSize: containerSize, withSize: viewSize, atAngle: angle)
        
        var newTransform = transform
        if scale < minScaleFactor {
            newTransform = CGAffineTransform(scaleX: minScaleFactor, y: minScaleFactor)
            newTransform = newTransform.rotated(by: angle)
            newTransform.tx = transform.tx
            newTransform.ty = transform.ty
            scale = minScaleFactor
        }
        
        // Figure out if nudging the View is needed
        let inverseTransform = newTransform.inverted()
        
        let auxView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: containerSize.width, height: containerSize.height))
        auxView.center = CGPoint(x: viewSize.width * 0.5, y: viewSize.height * 0.5)
        auxView.transform = inverseTransform
        
        if auxView.frame.minX < 0.0 {
            newTransform = newTransform.translatedBy(x: auxView.frame.minX, y: 0.0)
        } else if auxView.frame.maxX > viewSize.width {
            newTransform = newTransform.translatedBy(x: auxView.frame.maxX - viewSize.width, y: 0.0)
        }
        
        if auxView.frame.minY < 0.0 {
            newTransform = newTransform.translatedBy(x: 0.0, y: auxView.frame.minY)
        } else if auxView.frame.maxY > viewSize.height {
            newTransform = newTransform.translatedBy(x: 0.0, y: auxView.frame.maxY - viewSize.height)
        }
        
        return newTransform
    }

    /// Returns the scale (where 1.0 is the View's original size) needed to fill the Container
    /// IMPORTANT: Assumes that both views are centred
    ///
    /// - Parameters:
    ///   - containerSize: The size of the Container to fill
    ///   - size: The size of the View
    ///   - angle: The current rotation angle
    /// - Returns: The scale the View needs to be to fill the container
    static func scaleFactorToFill(containerSize: CGSize, withSize size: CGSize, atAngle angle: CGFloat) -> CGFloat {
        // FIXME: Is this angle correction necessary?
        var theta = abs(angle - 2.0 * .pi * trunc(angle / .pi / 2.0) - .pi)
        if theta > .pi / 2.0 {
            theta = abs(.pi - theta)
        }
        let h = size.height
        let H = containerSize.height
        let w = size.width
        let W = containerSize.width
        let scale1 = (H * cos(theta) + W * sin(theta)) / h
        let scale2 = (H * sin(theta) + W * cos(theta)) / w
        let scaleFactor = max(scale1, scale2)
        return scaleFactor
    }
}
