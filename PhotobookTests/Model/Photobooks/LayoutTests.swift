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

import XCTest
@testable import Photobook

class LayoutTests: XCTestCase {
    
    let validDictionary = ([
        "id": 10,
        "category": "squareCentred"
        ]) as [String: AnyObject]
    
    func testParse_shouldSucceedWithAValidDictionary() {
        let layout = Layout.parse(validDictionary)
        XCTAssertNotNil(layout, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_shouldReturnNilIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if id is missing")
    }
    
    func testParse_shouldReturnNilIfCategoryIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["category"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if category is missing")
    }
    
    func testEquality_shouldBeEqual() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertEqual(layout1, layout2)
    }
    
    func testEquality_shouldNotBeEqual_id() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 2, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertNotEqual(layout1, layout2)
    }

    func testEquality_shouldNotBeEqual_category() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 1, category: "Category2", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertNotEqual(layout1, layout2)
    }
}
