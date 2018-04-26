//
//  LayoutUtilsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 18/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class TestPanGestureRecognizer: UIPanGestureRecognizer {
    var x, y: CGFloat!
    
    override func translation(in view: UIView?) -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}

class LayoutUtilsTests: XCTestCase {
    
    private let identity = CGAffineTransform.identity
    private let containerSize = CGSize(width: 1.0, height: 1.0)
    private let parentView = UIView()
    private let initialTransform = CGAffineTransform.identity.translatedBy(x: 5.0, y: 6.0).scaledBy(x: 2.0, y: 2.0).rotated(by: .pi / 6.0)
    
    func testScaleToFill() {
        let images = [
            // Size, Angle, Expected scale
            (CGSize(width: 1.0, height: 1.0), CGFloat(0.0), CGFloat(1.0)),
            (CGSize(width: 2.0, height: 2.0), CGFloat(0.0), CGFloat(0.5)),
            (CGSize(width: 2.0, height: 3.0), CGFloat(0.0), CGFloat(0.5)),
            (CGSize(width: 0.5, height: 2.0), CGFloat(0.0), CGFloat(2.0)),
            (CGSize(width: 2.0, height: 2.0), CGFloat(30.0), CGFloat(0.57)),
            (CGSize(width: 3.0, height: 1.0), CGFloat(45.0), CGFloat(1.37)),
            (CGSize(width: 1.0, height: 1.0), CGFloat(270.0), CGFloat(1.16)),
            (CGSize(width: 2.0, height: 2.0), CGFloat(-30.0), CGFloat(0.57)),
            (CGSize(width: 2.0, height: 2.0), CGFloat(-270.0), CGFloat(0.58))
        ]
        
        for (index, image) in images.enumerated() {
            let scale = LayoutUtils.scaleToFill(containerSize: containerSize, withSize: image.0, atAngle: image.1)
            XCTAssertEqual(scale, image.2, accuracy: 0.01, "Scale for image \(index + 1) should be \(image.2), not \(scale)")
        }
    }
    
    // MARK: - Net CCW cuadrant angle
    func testNextCCWCuadrantAngle() {
        let pi = CGFloat.pi
        let angles: [(CGFloat, CGFloat)] = [
            // Angle, Expected cuadrant angle
            (CGFloat(0.0), -pi / 2.0),
            (-2.0 * pi, -2.5 * pi),
            (-pi / 6.0, -pi / 2.0),
            (-pi / 3.0, -pi / 2.0),
            (-pi * 2.0 / 3.0, -pi),
            (-pi * 0.99, -3.0 * pi / 2.0), // If close to a cuadrant, should return next one
            (pi / 6.0, 0.0),
            (pi / 3.0, 0.0)
        ]
        
        for (index, angle) in angles.enumerated() {
            let nextCuadrantAngle = LayoutUtils.nextCCWCuadrantAngle(to: angle.0)
            XCTAssertEqual(nextCuadrantAngle, angle.1, "Next cuadrant angle for angle \(index + 1) should be \(angle.1), not \(nextCuadrantAngle)")
        }
    }
    
    // MARK: - Centre transform
    func testCenterTransform() {
        let transform = identity.translatedBy(x: 4.0, y: 4.0)
        let parentView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 70.0))
        let expectedTransform = identity.translatedBy(x: -6.0, y: -1.0)
        let currentPoint = CGPoint(x: 40.0, y: 30.0)
        
        let newTransform = LayoutUtils.centerTransform(transform, inParentView: parentView, fromPoint: currentPoint)
        XCTAssertEqual(newTransform, expectedTransform)
    }
    
    // MARK: - Adjust transform with Recognizer
    func testAdjustTransformWithRecognizer_rotatesTransform() {
        let rotationGestureRecognizer = UIRotationGestureRecognizer()
        rotationGestureRecognizer.rotation = .pi / 6.0 // 30 degrees
        
        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: rotationGestureRecognizer, inParentView: parentView)
        
        // Original rotation .pi / 6 + additional .pi / 6 = result .pi / 3
        XCTAssertEqual(newTransform.angle, .pi / 3.0, accuracy: 0.01)
    }
    
    func testAdjustTransformWithRecognizer_scalesTransform() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.scale = 2.0
        
        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: pinchGestureRecognizer, inParentView: parentView)
        
        // Original scale 2 x new scale 2 = result 4
        XCTAssertEqual(newTransform.scale, 4.0, accuracy: 0.01)
    }

    func testAdjustTransformWithRecognizer_scaleBelowOne() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.scale = 0.7
        
        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: pinchGestureRecognizer, inParentView: parentView)
        
        // Original scale 2 x new scale 0.5 = result max Scale 3.0
        XCTAssertEqual(newTransform.scale, 1.75, accuracy: 0.01)
    }

    func testAdjustTransformWithRecognizer_maxScale() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.scale = 10.0

        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: pinchGestureRecognizer, inParentView: parentView, maxScale: 3.0)
        
        // Original scale 2 x new scale 10.0 = result max Scale 3.0
        XCTAssertEqual(newTransform.scale, 3.0, accuracy: 0.01)
    }
    
    func testAdjustTransformWithRecognizer_pansTransform() {
        let panGestureRecognizer = TestPanGestureRecognizer()
        panGestureRecognizer.x = 4.0
        panGestureRecognizer.y = 6.0
        
        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: panGestureRecognizer, inParentView: parentView)
        
        // Original translation (5.0, 6.0) + new translation (4.0, 6.0) = result (9.0, 12.0)
        XCTAssertTrue(newTransform.tx == 9.0 && newTransform.ty == 12.0)
    }
    
    func testAdjustTransformWithRecognizer_unrecognizedGesture() {
        let gestureRecognizer = UIGestureRecognizer()
        let newTransform = LayoutUtils.adjustTransform(initialTransform, withRecognizer: gestureRecognizer, inParentView: parentView)
        XCTAssertEqual(newTransform, initialTransform)
    }

    func testAdjustTransformByFactorXFactorY_xIsNAN_shouldUseY() {
        let transform = LayoutUtils.adjustTransform(identity, byFactorX: .nan, factorY: 0.5)
        let expectedTransform = CGAffineTransform.identity.scaledBy(x: 0.5, y: 0.5)
        XCTAssertEqual(transform, expectedTransform)
    }
    
    func testAdjustTransformByFactorXFactorY_yIsNAN_shouldUseX() {
        let transform = LayoutUtils.adjustTransform(identity, byFactorX: 0.2, factorY: .nan)
        let expectedTransform = CGAffineTransform.identity.scaledBy(x: 0.2, y: 0.2)
        XCTAssertEqual(transform, expectedTransform)
    }
    
    func testAdjustTransformByFactorXFactorY_xAndYAreNan_shouldReturnInputTransform() {
        let transform = LayoutUtils.adjustTransform(identity, byFactorX: .nan, factorY: .nan)
        XCTAssertEqual(transform, identity)
    }
    
    func testAdjustTransformByFactorXFactorY() {
        let transforms = [
            (CGAffineTransform(a: 0.2, b: 0.0, c: 0.0, d: 0.2, tx: 20.0, ty: -5.0), CGFloat(0.5), CGFloat(0.4)),
            (CGAffineTransform(a: 0.1, b: 0.4, c: 0.6, d: 0.1, tx: 10.0, ty: 5.0), CGFloat(0.5), CGFloat(0.4)),
            (CGAffineTransform(a: 0.6, b: 0.4, c: 0.3, d: 0.2, tx: 0.0, ty: 0.0), CGFloat(0.5), CGFloat(0.4)),
            (CGAffineTransform(a: 0.02, b: 2.0, c: 5.0, d: 0.02, tx: 0.0, ty: 1.0), CGFloat(0.5), CGFloat(0.4)),
            (CGAffineTransform(a: 0.9, b: -4.0, c: 5.5, d: 0.2, tx: -40.0, ty: 30.0), CGFloat(0.5), CGFloat(0.4))
        ]
        
        let expectedTransforms = [
            CGAffineTransform(a: 0.1, b: 0.0, c: 0.0, d: 0.08, tx: 10.0, ty: -2.0),
            CGAffineTransform(a: 0.0737643306116732, b: 0.236045857957354, c: -0.295057322446693, d: 0.0590114644893386, tx: 5.0, ty: 2.0),
            CGAffineTransform(a: 0.279078152825719, b: 0.14884168150705, c: -0.186052101883813, d: 0.223262522260575, tx: 0.0, ty: 0.0),
            CGAffineTransform(a: 0.0249989500829427, b: 1.99991600663544, c: -2.4998950082943, d: 0.0199991600663542, tx: 0.0, ty: 0.4),
            CGAffineTransform(a: 0.611687186038219, b: -2.17488777258034, c: 2.71860971572542, d: 0.489349748830576, tx: -20.0, ty: 12.0)
        ]
        
        for (index, transform) in transforms.enumerated() {
            let resultTransform = LayoutUtils.adjustTransform(transform.0, byFactorX: transform.1, factorY: transform.2)
            XCTAssertTrue(resultTransform ==~ expectedTransforms[index], "Result for transform \(index + 1) should be \(expectedTransforms[index]), not \(resultTransform)")
        }
    }
    
    let adjustContainerSize = CGSize(width: 100.0, height: 100.0)
    let adjustViewSize = CGSize(width: 150.0, height: 150.0)

    // MARK: - Adjust transform for view size in container size
    func testAdjustTransformForViewSizeInContainerSize_nudgesViewLeft() {
        // Move view right and rotate it 45 degrees counterclockwise
        let initialTransform = identity.translatedBy(x: 25.0, y: 0.0).rotated(by: .pi / 4.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should nudge view to the left
        XCTAssertEqual(newTransform.tx, 6.06, accuracy: 0.01)
    }
    
    func testAdjustTransformForViewSizeInContainerSize_nudgesViewRight() {
        // Move view left by 25.0 and rotate it 45 degrees counterclockwise
        let initialTransform = identity.translatedBy(x: -25.0, y: 0.0).rotated(by: .pi / 4.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should nudge view to the right
        XCTAssertEqual(newTransform.tx, -6.06, accuracy: 0.01)
    }

    func testAdjustTransformForViewSizeInContainerSize_nudgesViewUp() {
        // Move view down by 25.0 and rotate it 45 degrees counterclockwise
        let initialTransform = identity.translatedBy(x: 0.0, y: 25.0).rotated(by: .pi / 4.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should nudge view up
        XCTAssertEqual(newTransform.ty, 6.06, accuracy: 0.01)
    }
    
    func testAdjustTransformForViewSizeInContainerSize_nudgesViewDown() {
        // Move view up by 25.0 and rotate it 45 degrees counterclockwise
        let initialTransform = identity.translatedBy(x: 0.0, y: -25.0).rotated(by: .pi / 4.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should nudge view down
        XCTAssertEqual(newTransform.ty, -6.06, accuracy: 0.01)
    }

    func testAdjustTransformForViewSizeInContainerSize_nudgesViewUpLeftThenDownLeft() {
        // Move view right and rotate it 30 degrees counterclockwise
        let initialTransform = identity.translatedBy(x: 25.0, y: 0.0).rotated(by: .pi / 6.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should:
        // 1. Nudge the view to cover the parent view's top-left corner
        // 2. Nudge the view to cover the parent view's bottom-left corner
        XCTAssertEqual(newTransform.tx, 9.15, accuracy: 0.01)
        XCTAssertEqual(newTransform.ty, -2.45, accuracy: 0.01)
    }

    func testAdjustTransformForViewSizeInContainerSize_nudgesViewDownAndRight() {
        // Move view left and rotate it 30 degrees clockwise
        let initialTransform = identity.translatedBy(x: -25.0, y: 0.0).rotated(by: -.pi / 6.0)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        // Should:
        // 1. Nudge the view to cover the parent view's bottom-right corner
        // 2. Nudge the view to cover the parent view's top-right corner
        XCTAssertEqual(newTransform.tx, -9.15, accuracy: 0.01)
        XCTAssertEqual(newTransform.ty, -2.45, accuracy: 0.01)
    }
    
    func testAdjustTransformForViewSizeInContainerSize_snapsToZero() {
        let angles: [CGFloat] = [ 2.9, 2.0, 1.0, -2.9, -2.0, -1.0, 0.0 ]
        
        for (index, angle) in angles.enumerated() {
            let initialTransform = identity.rotated(by: angle * .pi / 180.0) // Rotate 2 degrees clockwise
            let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
            XCTAssertEqual(newTransform.angle, 0.0, "Input angle \(index + 1) should snap to zero")

        }
    }
    
    func testAdjustTransformForViewSizeInContainerSize_doesNotSnapToZero() {
        let angles: [CGFloat] = [ 3.1, 363.0, -3.1, -363.0 ]
        
        for (index, angle) in angles.enumerated() {
            let initialTransform = identity.rotated(by: angle * .pi / 180.0) // Rotate 2 degrees clockwise
            let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
            XCTAssertEqual(newTransform.angle, initialTransform.angle, "Input angle \(index + 1) should not change")
            
        }
    }
    
    func testAdjustTransformForViewSizeInContainerSize_enforcesMinimumScale() {
        let minScale = LayoutUtils.scaleToFill(containerSize: adjustContainerSize, withSize: adjustViewSize, atAngle: 0.0)
        
        let initialTransform = identity.scaledBy(x: 0.1, y: 0.1)
        let newTransform = LayoutUtils.adjustTransform(initialTransform, forViewSize: adjustViewSize, inContainerSize: adjustContainerSize)
        XCTAssertEqual(newTransform.scale, minScale)
    }
}
