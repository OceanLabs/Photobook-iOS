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
            (CGSize(width: 2.0, height: 2.0), CGFloat(-270.0), CGFloat(0.58)),
        ]
        
        for (index, image) in images.enumerated() {
            let scale = LayoutUtils.scaleToFill(containerSize: containerSize, withSize: image.0, atAngle: image.1)
            XCTAssertEqual(scale, image.2, accuracy: 0.01, "Scale for image \(index+1) should be \(image.2), not \(scale)")
        }
    }
    
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
            (pi / 3.0, 0.0),
        ]
        
        for (index, angle) in angles.enumerated() {
            let nextCuadrantAngle = LayoutUtils.nextCCWCuadrantAngle(to: angle.0)
            XCTAssertEqual(nextCuadrantAngle, angle.1, "Next cuadrant angle for angle \(index+1) should be \(angle.1), not \(nextCuadrantAngle)")
        }
    }
    
    func testCenterTransform() {
        let transform = identity.translatedBy(x: 4.0, y: 4.0)
        let parentView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 70.0))
        let expectedTransform = identity.translatedBy(x: -6.0, y: -1.0)
        let currentPoint = CGPoint(x: 40.0, y: 30.0)
        
        let newTransform = LayoutUtils.centerTransform(transform, inParentView: parentView, fromPoint: currentPoint)
        XCTAssertEqual(newTransform, expectedTransform)
    }
    
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
}
