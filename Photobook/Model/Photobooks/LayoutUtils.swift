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

    private struct Constants {
        static let snapToZeroThreshold: CGFloat = 3.0
    }
    
    /// Amends a transform that will scale and nudge a View to fill a Container from its current transform
    /// IMPORTANT: It assumes that the View would be centred in the Container if the transform were the identity.
    ///
    /// - Parameters:
    ///   - transform: The current transform
    ///   - viewSize: The size of the View to fill the Container
    ///   - containerSize: The size of the Container
    /// - Returns: A new adjusted transform where the Container will be completely filled by the View
    static func adjustTransform(_ transform: CGAffineTransform, forViewSize viewSize: CGSize, inContainerSize containerSize: CGSize) -> CGAffineTransform {
        var angle = transform.angle
        var scale = transform.scale
        
        // Check if we need to snap to 0 degrees
        if abs(angle.inDegrees()) < Constants.snapToZeroThreshold {
            angle = 0.0
        }
        
        // Check the minimum scale factor to fill the container taking into consideration the view's current rotation
        let minScale = scaleToFill(containerSize: containerSize, withSize: viewSize, atAngle: angle)

        if scale < minScale {
            scale = minScale
        }
        
        var newTransform = CGAffineTransform(scaleX: scale, y: scale)
        newTransform = newTransform.rotated(by: angle)
        newTransform.tx = transform.tx
        newTransform.ty = transform.ty
        
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
    
    /// Amends a transform in response to a zooming, panning or rotating gesture
    ///
    /// - Parameters:
    ///   - transform: The current transform
    ///   - recognizer: The recognizer that responded to the user's gesture
    ///   - parentView: The view to use as a coordinate space for the gesture
    /// - Returns: A new adjusted transform that reflects the user's intent
    static func adjustTransform(_ transform: CGAffineTransform, withRecognizer recognizer: UIGestureRecognizer, inParentView parentView: UIView, maxScale: CGFloat = CGFloat.greatestFiniteMagnitude) -> CGAffineTransform {
        if let rotateRecognizer = recognizer as? UIRotationGestureRecognizer {

            return transform.rotated(by: rotateRecognizer.rotation)
        }
        if let pinchRecognizer = recognizer as? UIPinchGestureRecognizer {
            var scale = pinchRecognizer.scale
            
            // Makes it harder to scale down the image below 1.0
            if scale < 1.0 {
                scale = 1.4 - pow(0.4, scale)
            }
            else if transform.scale * scale > maxScale {
                scale = maxScale / transform.scale
            }
            return transform.scaledBy(x: scale, y: scale)
        }
        if let panRecognizer = recognizer as? UIPanGestureRecognizer {
            let deltaX = panRecognizer.translation(in: parentView).x
            let deltaY = panRecognizer.translation(in: parentView).y
            
            let angle = transform.angle
            let scale = transform.scale
            
            let tx = (deltaX * cos(angle) + deltaY * sin(angle)) / scale
            let ty = (-deltaX * sin(angle) + deltaY * cos(angle)) / scale
            
            return transform.translatedBy(x: tx, y: ty)
        }
        return transform
    }
    
    /// Amends a transform by a scale factor. This is useful when we want to scale the user effects to a smaller or larger scope and keep the same visual results.
    ///
    /// - Parameters:
    ///   - transform: The current transform
    ///   - byFactorX: The factor to apply to the X axis
    ///   - byFactorY: The factor to apply to the Y axis
    /// - Returns: A new scaled transform
    static func adjustTransform(_ transform: CGAffineTransform, byFactorX x: CGFloat, factorY y: CGFloat) -> CGAffineTransform {
        guard !(x.isNaN && y.isNaN) else { return transform }
        let scaleX = x.isNaN ? y : x
        let scaleY = y.isNaN ? x : y
        
        let angle = transform.angle
        let scale = transform.scale
        
        var newTransform = CGAffineTransform(scaleX: scale * scaleX, y: scale * scaleY)
        newTransform = newTransform.rotated(by: angle)
        newTransform.tx = transform.tx * scaleX
        newTransform.ty = transform.ty * scaleY
        
        return newTransform
    }

    /// Amends a view's transform to use the centre of the parentView as reference.
    /// This can be used after rotating the view around an arbitrary anchor point to take the transform back to a valid state.
    ///
    /// - Parameters:
    ///   - transform: The current transform
    ///   - parentView: The view to use as a coordinate space
    ///   - point: The current center of the view
    /// - Returns: A transform where the translation takes the centre of the parentView as reference
    static func centerTransform(_ transform: CGAffineTransform, inParentView parentView: UIView, fromPoint point: CGPoint) -> CGAffineTransform {
        var transform = transform
        transform.tx += point.x - parentView.bounds.midX
        transform.ty += point.y - parentView.bounds.midY
        return transform
    }

    /// Returns the scale (where 1.0 is the View's original size) needed to fill the Container
    /// IMPORTANT: Assumes that both views are centred
    ///
    /// - Parameters:
    ///   - containerSize: The size of the Container to fill
    ///   - size: The size of the View
    ///   - angle: The current rotation angle
    /// - Returns: The scale the View needs to be to fill the container
    static func scaleToFill(containerSize: CGSize, withSize size: CGSize, atAngle angle: CGFloat) -> CGFloat {
        let angle = abs(angle)
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
    
    static func nextCCWCuadrantAngle(to angle: CGFloat) -> CGFloat {
        var rotateTo = floor(angle / (.pi * 0.5)) * .pi * 0.5
        
        if angle ==~ rotateTo {
            rotateTo = angle - .pi * 0.5
        }
        if abs(rotateTo) < CGFloat.minPrecision {
            rotateTo = 0.0
        }
        return rotateTo
    }
}

extension CGAffineTransform {

    // Rotation angle
    var angle: CGFloat {
        return atan2(self.b, self.a)
    }
    
    // Scale
    var scale: CGFloat {
        return sqrt(self.a * self.a + self.c * self.c)
    }
}

