//
//  LayoutUtilsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 18/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class LayoutUtilsTests: XCTestCase {
    
    let containerSize = CGSize(width: 1.0, height: 1.0)
    
    private let identity = CGAffineTransform.identity
    
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
}
