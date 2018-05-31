//
//  PhotobookProductTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class PhotobookProductTests: XCTestCase {

    let template = PhotobookTemplate(id: 1, name: "template", templateId: "photobook", kiteId: "photobook", coverSize: CGSize(width: 200.0, height: 100.0), pageSize: CGSize(width: 200.0, height: 100.0), spineTextRatio: 0.8, coverLayouts: Array(1...5), layouts: Array(1...5))
    let assets: [Asset] = {
        var temp = [TestPhotosAsset]()
        for i in 0 ..< 10 {
            let width = i % 2 == 0 ? 2000.0 : 3000.0
            let height = i % 2 == 0 ? 3000.0 : 2000.0
            temp.append(TestPhotosAsset(size: CGSize(width: width, height: height)))
        }
        return temp
    }()
    var coverLayouts: [Layout]!
    var layouts: [Layout]!
    let portraitRect = CGRect(x: 0.0, y: 0.0, width: 0.5, height: 0.9)
    let landscapeRect = CGRect(x: 0.0, y: 0.0, width: 0.9, height: 0.5)
    var photobookProduct: PhotobookProduct!
    
    override func setUp() {
        coverLayouts = [Layout]()
        layouts = [Layout]()

        for i in 1 ... 5 {
            let layoutBox = LayoutBox(id: 1, rect: i % 2 == 0 ? portraitRect : landscapeRect)
            coverLayouts.append(Layout(id: i, category: "cover\(i)", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: false))
            layouts.append(Layout(id: i, category: "page\(i)", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: i == 5))
        }
        
        photobookProduct = PhotobookProduct(template: template, assets: assets, coverLayouts: coverLayouts, layouts: layouts)
    }
    
    // MARK: - Init
    func testInit_setsTemplate() {
        XCTAssertEqual(photobookProduct.template, template)
    }

    func testInit_coverIsNotTheFirstAsset() {
        let firstAsset = photobookProduct.productLayouts.first?.asset
        XCTAssertTrue(firstAsset != nil && firstAsset! !== assets[0])
    }
    
    func testInit_shouldHaveMinimumNumberOfLayouts() {
        XCTAssertEqual(photobookProduct.productLayouts.count, template.minPages)
    }
    
    // MARK: - EmptyLayoutIndices
    func testEmptyLayoutIndices_shouldReturnLastTen() {
        let emptyLayoutIndices = photobookProduct.emptyLayoutIndices
        XCTAssertEqual(emptyLayoutIndices, Array(11...19))
    }
    
    func testEmptyLayoutIndices_shouldCountDoublePageLayoutsAsTwoIndeces() {
        photobookProduct.productLayouts[12].layout.isDoubleLayout = true
        let emptyLayoutIndices = photobookProduct.emptyLayoutIndices
        XCTAssertEqual(emptyLayoutIndices, Array(11...20))
    }

    func testEmptyLayoutIndices_shouldIgnoreEmptyTextIfLayoutHasAPhoto() {
        photobookProduct.productLayouts[11].asset = TestPhotosAsset()
        let emptyLayoutIndices = photobookProduct.emptyLayoutIndices
        XCTAssertFalse(emptyLayoutIndices!.contains(11))
    }
    
    func testEmptyLayoutIndices_shouldIncludeEmptyTextOnlyLayouts() {
        photobookProduct.productLayouts.first!.layout.imageLayoutBox = nil
        let emptyLayoutIndices = photobookProduct.emptyLayoutIndices
        XCTAssertTrue(emptyLayoutIndices!.contains(0))
    }

    func testEmptyLayoutIndeces_shouldReturnNilWithoutEmptyLayouts() {
        for i in 11 ..< 20 {
            photobookProduct.productLayouts[i].asset = TestPhotosAsset()
        }
        let emptyLayoutIndices = photobookProduct.emptyLayoutIndices
        XCTAssertNil(emptyLayoutIndices)
    }

    // MARK: - SetTemplate
    func testSetTemplate() {
        var coverLayouts2 = [Layout]()
        var layouts2 = [Layout]()
        
        let size = CGSize(width: 200.0, height: 100.0)
        let template2 = PhotobookTemplate(id: 2, name: "template2", templateId: "photobook2", kiteId: "photobook2", coverSize: size, pageSize: size, spineTextRatio: 0.8, coverLayouts: Array(6...10), layouts: Array(6...10))

        // Create new fake layouts with different IDs but same categories
        for i in 1 ... 5 {
            let layoutBox = LayoutBox(id: 1, rect: i % 2 == 0 ? portraitRect : landscapeRect)
            coverLayouts2.append(Layout(id: i + 5, category: "cover\(i)", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: false))
            layouts2.append(Layout(id: i + 5, category: "page\(i)", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: i == 5))
        }

        // Get a reference to the current layouts
        let originalLayouts = photobookProduct.productLayouts.map { return $0.layout }
        photobookProduct.setTemplate(template2, coverLayouts: coverLayouts2, layouts: layouts2)
        
        // Number of layouts should not change
        XCTAssertEqual(originalLayouts.count, photobookProduct.productLayouts.count)
        
        // Layouts should've been replaced with new ones of the same category
        for i in 0 ..< originalLayouts.count {
            XCTAssertTrue(originalLayouts[i]!.category == photobookProduct.productLayouts[i].layout.category &&
                originalLayouts[i]!.id != photobookProduct.productLayouts[i].layout.id)
        }
    }
    
    // MARK: - Setters
    func testSetLayout() {
        let layoutBox = LayoutBox(id: 1, rect: portraitRect)
        let layout = Layout(id: 99, category: "page99", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: false)
        photobookProduct.setLayout(layout, forPage: 1)
        XCTAssertEqual(photobookProduct.productLayouts[1].layout, layout)
    }

    func testSetAsset() {
        let asset = TestPhotosAsset()
        photobookProduct.setAsset(asset, forPage: 1)
        XCTAssertTrue(photobookProduct.productLayouts[1].asset === asset)
    }
    
    func testSetText() {
        let text = "This is alternative text"
        photobookProduct.setText(text, forPage: 1)
        XCTAssertEqual(photobookProduct.productLayouts[1].text, text)
    }
    
    // MARK: - Indices & Spreads
    func testSpreadIndexForLayoutIndex() {
        for index in 0 ..< photobookProduct.productLayouts.count {
            let layoutIndex = photobookProduct.spreadIndex(for: index)
            if index == 0 {
                XCTAssertNil(layoutIndex)
                continue
            } else if index == 1 {
                XCTAssertEqual(layoutIndex, 0)
                continue
            }
            XCTAssertEqual(index / 2, layoutIndex!)
        }
    }
    
    func testSpreadIndexForLayoutIndex_withDoubleLayout() {
        // Make layout 2 a double layout
        photobookProduct.productLayouts[2].layout.isDoubleLayout = true
        
        // Layout 3 should be pushed one spread to spread 2
        let layoutIndex = photobookProduct.spreadIndex(for: 3)
        XCTAssertEqual(layoutIndex, 2)
    }
    
    func testProductLayoutIndexForSpreadIndex() {
        for spreadIndex in 0 ..< 10 {
            let productLayoutIndex = photobookProduct.productLayoutIndex(for: spreadIndex)
            if spreadIndex == 0 {
                XCTAssertNil(productLayoutIndex)
                continue
            }
            XCTAssertEqual(productLayoutIndex, spreadIndex * 2)
        }
    }
    
    func testProductLayoutIndexForSpreadIndex_withDoubleLayout() {
        // Make layout 2 a double layout
        photobookProduct.productLayouts[2].layout.isDoubleLayout = true
        
        // Layout 3 should be pushed one spread to spread 2
        let productLayoutIndex = photobookProduct.spreadIndex(for: 3)
        XCTAssertEqual(productLayoutIndex, 2)
    }
    
    // MARK: - Page handling
    func testAddPage() {
        let numberOfLayouts = photobookProduct.productLayouts.count
        let index = numberOfLayouts - 1
        let layout = photobookProduct.productLayouts[index]
        
        photobookProduct.addPage(at: index)
        
        // Check that previous layout at that index has moved down one
        XCTAssertTrue(photobookProduct.productLayouts[index + 1] === layout)
        // Check that number of layouts has increased by one
        XCTAssertEqual(photobookProduct.productLayouts.count, numberOfLayouts + 1)
    }

    func testAddDoubleSpread() {
        let numberOfLayouts = photobookProduct.productLayouts.count
        let index = numberOfLayouts - 1
        let layout = photobookProduct.productLayouts[index]
        
        photobookProduct.addDoubleSpread(at: index)
        
        // Check that previous layout at that index has moved down two
        XCTAssertTrue(photobookProduct.productLayouts[index + 2] === layout)
        // Check that number of layouts has increased by two
        XCTAssertEqual(photobookProduct.productLayouts.count, numberOfLayouts + 2)
    }
    
    func testAddPages() {
        let numberOfLayouts = photobookProduct.productLayouts.count
        let index = numberOfLayouts - 1
        let layout = photobookProduct.productLayouts[index]
        
        var productLayouts = [ProductLayout]()
        for i in 0 ..< 5 {
            productLayouts.append(ProductLayout(layout: photobookProduct.layouts![i]))
        }
        
        photobookProduct.addPages(at: index, pages: productLayouts)
        
        // Check that previous layout at that index has moved down five
        XCTAssertTrue(photobookProduct.productLayouts[index + 5] === layout)
        // Check that number of layouts has increased by 5
        XCTAssertEqual(photobookProduct.productLayouts.count, numberOfLayouts + 5)
        // Check that the passed layouts are in place
        for i in 0 ..< 5 {
            XCTAssertTrue(productLayouts[i] === photobookProduct.productLayouts[index + i])
        }
    }
    
    func testDeletePages_singleLayout() {
        let numberOfLayouts = photobookProduct.productLayouts.count
        let index = numberOfLayouts / 2
        let productLayout = photobookProduct.productLayouts[index]
        
        photobookProduct.deletePages(for: productLayout)
        
        XCTAssertFalse(photobookProduct.productLayouts[index] === productLayout)
        // Check that number of layouts has decreased by 2
        XCTAssertEqual(photobookProduct.productLayouts.count, numberOfLayouts - 2)
    }
    
    func testDeletePages_doubleLayout() {
        let numberOfLayouts = photobookProduct.productLayouts.count
        let index = numberOfLayouts / 2
        let productLayout = photobookProduct.productLayouts[index]
        productLayout.layout.isDoubleLayout = true
        
        photobookProduct.deletePages(for: productLayout)
        
        XCTAssertFalse(photobookProduct.productLayouts[index] === productLayout)
        // Check that number of layouts has decreased by 1
        XCTAssertEqual(photobookProduct.productLayouts.count, numberOfLayouts - 1)
    }
    
    func testPageType_withoutDoublePages() {
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: 0), .cover)
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: 1), .first)
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: photobookProduct.productLayouts.count - 1), .last)
        for i in stride(from: 2, to: photobookProduct.productLayouts.count - 2, by: 2) {
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i), .left)
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i + 1), .right)
        }
    }

    func testPageType_withADoublePage() {
        // Add a double-page layout
        let productLayout = photobookProduct.productLayouts[1].shallowCopy()
        productLayout.layout.isDoubleLayout = true
        let index = 4
        photobookProduct.productLayouts.insert(productLayout, at: index)
        photobookProduct.productLayouts.remove(at: photobookProduct.productLayouts.count - 1)
        
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: 0), .cover)
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: 1), .first)
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: photobookProduct.productLayouts.count - 1), .last)
        for i in stride(from: 2, to: index - 1, by: 2) {
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i), .left)
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i + 1), .right)
        }
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: index), .left)
        for i in stride(from: index + 1, to: photobookProduct.productLayouts.count - 2, by: 2) {
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i), .left)
            XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: i + 1), .right)
        }
    }

    func testPageType_withDoubleLayout() {
        let index = 2
        let productLayout = photobookProduct.productLayouts[index]
        productLayout.layout.isDoubleLayout = true
        XCTAssertEqual(photobookProduct.pageType(forLayoutIndex: index + 1), .left)
    }
    
    func testMoveLayout_downWithSingleLayouts() {
        let sourceIndex = 2
        let destinationIndex = 4
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        let productLayoutOpposite = photobookProduct.productLayouts[sourceIndex + 1]
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex])
        XCTAssertTrue(productLayoutOpposite === photobookProduct.productLayouts[destinationIndex + 1])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[destinationIndex - 2])
    }
    
    func testMoveLayout_downWithDoubleLayoutSource() {
        let sourceIndex = 2
        let destinationIndex = 5
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        productLayoutToMove.layout.isDoubleLayout = true
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        // The destination and opposite pages should move up
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex + 1])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[destinationIndex - 1])
    }

    func testMoveLayout_downWithDoubleLayoutDestination() {
        let sourceIndex = 2
        let destinationIndex = 6
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        let productLayoutOpposite = photobookProduct.productLayouts[sourceIndex + 1]
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        productLayoutAtDestination.layout.isDoubleLayout = true
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex - 1])
        XCTAssertTrue(productLayoutOpposite === photobookProduct.productLayouts[destinationIndex])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[destinationIndex - 2])
    }

    func testMoveLayout_downWithDoubleLayouts() {
        let sourceIndex = 2
        let destinationIndex = 5
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        productLayoutToMove.layout.isDoubleLayout = true
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        productLayoutAtDestination.layout.isDoubleLayout = true
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[destinationIndex - 1])
    }

    func testMoveLayout_upWithSingleLayouts() {
        let sourceIndex = 4
        let destinationIndex = 2
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        let productLayoutToMoveOpposite = photobookProduct.productLayouts[sourceIndex + 1]
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        let productLayoutAtDestinationOpposite = photobookProduct.productLayouts[destinationIndex + 1]
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex])
        XCTAssertTrue(productLayoutToMoveOpposite === photobookProduct.productLayouts[destinationIndex + 1])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[sourceIndex])
        XCTAssertTrue(productLayoutAtDestinationOpposite === photobookProduct.productLayouts[sourceIndex + 1])
    }

    func testMoveLayout_upWithDoubleLayoutSource() {
        let sourceIndex = 6
        let destinationIndex = 2
        let productLayoutToMove = photobookProduct.productLayouts[sourceIndex]
        productLayoutToMove.layout.isDoubleLayout = true
        let productLayoutAtDestination = photobookProduct.productLayouts[destinationIndex]
        
        photobookProduct.moveLayout(from: sourceIndex, to: destinationIndex)
        
        // The destination and opposite pages should move up
        XCTAssertTrue(productLayoutToMove === photobookProduct.productLayouts[destinationIndex])
        XCTAssertTrue(productLayoutAtDestination === photobookProduct.productLayouts[destinationIndex + 1])
    }

    func testReplaceLayout_withTwoSingleLayouts_leftPage() {
        // Make a copy of a layout to use
        let index = 2
        let productLayout = photobookProduct.productLayouts[4].shallowCopy()
        let productLayoutToReplace = photobookProduct.productLayouts[index]
        let productLayoutOpposite = photobookProduct.productLayouts[index + 1]
        
        photobookProduct.replaceLayout(at: index, with: productLayout, pageType: .left)
        
        XCTAssertTrue(productLayout === photobookProduct.productLayouts[index])
        // Check that opposite page is intact
        XCTAssertTrue(productLayoutOpposite === photobookProduct.productLayouts[index + 1])
        // Check that the layout to replace is gone
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutToReplace })
    }

    func testReplaceLayout_withTwoSingleLayouts_rightPage() {
        // Make a copy of a layout to use
        let index = 3
        let productLayout = photobookProduct.productLayouts[4].shallowCopy()
        let productLayoutToReplace = photobookProduct.productLayouts[index]
        let productLayoutOpposite = photobookProduct.productLayouts[index - 1]
        
        photobookProduct.replaceLayout(at: index, with: productLayout, pageType: .right)
        
        XCTAssertTrue(productLayout === photobookProduct.productLayouts[index])
        // Check that opposite page is intact
        XCTAssertTrue(productLayoutOpposite === photobookProduct.productLayouts[index - 1])
        // Check that the layout to replace is gone
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutToReplace })
    }
    
    func testReplaceLayout_singleToDouble_leftPage() {
        // Make a copy of a layout to use
        let index = 2
        let productLayout = photobookProduct.productLayouts[4].shallowCopy()
        productLayout.layout.isDoubleLayout = true
        
        let productLayoutToReplace = photobookProduct.productLayouts[index]
        let productLayoutOpposite = photobookProduct.productLayouts[index + 1]
        
        photobookProduct.replaceLayout(at: index, with: productLayout, pageType: .left)
        
        XCTAssertTrue(productLayout === photobookProduct.productLayouts[index])
        // Check that the layout to replace is gone
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutToReplace })
        // Check that opposite page is gone too
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutOpposite })
    }

    func testReplaceLayout_singleToDouble_rightPage() {
        // Make a copy of a layout to use
        let index = 3
        let productLayout = photobookProduct.productLayouts[4].shallowCopy()
        productLayout.layout.isDoubleLayout = true
        
        let productLayoutToReplace = photobookProduct.productLayouts[index]
        let productLayoutOpposite = photobookProduct.productLayouts[index - 1]
        
        photobookProduct.replaceLayout(at: index, with: productLayout, pageType: .right)
        
        XCTAssertTrue(productLayout === photobookProduct.productLayouts[index - 1])
        // Check that the layout to replace is gone
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutToReplace })
        // Check that opposite page is gone too
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutOpposite })
    }

    func testReplaceLayout_doubleToSingle() {
        // Make a copy of a layout to use
        let index = 3
        let productLayout = photobookProduct.productLayouts[4].shallowCopy()
        let productLayoutToReplace = photobookProduct.productLayouts[index]
        productLayoutToReplace.layout.isDoubleLayout = true
        let productLayoutNext = photobookProduct.productLayouts[index + 1]
        
        photobookProduct.replaceLayout(at: index, with: productLayout, pageType: .left)
        
        XCTAssertTrue(productLayout === photobookProduct.productLayouts[index])
        // Check that the layout to replace is gone
        XCTAssertFalse(photobookProduct.productLayouts.contains { $0 === productLayoutToReplace })
        // Check that next page has moved down one to accomodate the opposite page
        XCTAssertFalse(productLayoutNext === photobookProduct.productLayouts[index + 1])
    }
}
