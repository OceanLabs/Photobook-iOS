//
//  XCTestCaseExtensions.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")

let testUrlString = "https://www.jojofun.co.uk/clowns/"
let testUrl = URL(string: testUrlString)!
let testSize = CGSize(width: 100.0, height: 200.0)

extension XCTestCase {
    
    func XCTAssertEqualOptional<T>(_ expression1: @autoclosure () -> T?, _ expression2: @autoclosure () -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
        
        let exp1 = expression1()
        let exp2 = expression2()
        if let exp1_float = exp1 as? CGFloat, let exp2_float = exp2 as? CGFloat, exp1_float ==~ exp2_float {
            return
        }
        if let exp1_decimal = exp1 as? Decimal, let exp2_decimal = exp2 as? Decimal, exp1_decimal ==~ exp2_decimal {
            return
        }
        if exp1 != exp2 {
            recordFailure(withDescription: "\(String(describing: exp1)) is not equal to \(String(describing: exp2))", inFile: #file, atLine: #line, expected: true)
        }
    }
 
    func expectFatalError(expectedMessage: String, testcase: @escaping () -> Void) {
        
        // arrange
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String? = nil
        
        // override fatalError. This will pause forever when fatalError is called.
        FatalErrorUtil.replaceFatalError { message, _, _ in
            assertionMessage = message
            expectation.fulfill()
            unreachable()
        }
        
        // act, perform on separate thead because a call to fatalError pauses forever
        DispatchQueue.global(qos: .userInitiated).async(execute: testcase)
        
        waitForExpectations(timeout: 0.1) { _ in
            // assert
            XCTAssertEqual(assertionMessage, expectedMessage)
            
            // clean up
            FatalErrorUtil.restoreFatalError()
        }
    }
    
    func archiveObject(_ object: Any, to file: String) -> Bool {
        if !FileManager.default.fileExists(atPath: photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                XCTFail("Could not create photobook directory")
            }
        }
        let filePath = photobookDirectory.appending(file)
        return NSKeyedArchiver.archiveRootObject(object, toFile: filePath)
    }
    
    func unarchiveObject(from file: String) -> Any? {
        let filePath = photobookDirectory.appending(file)
        return NSKeyedUnarchiver.unarchiveObject(withFile: filePath)
    }
}
