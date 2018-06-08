//
//  OrderTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class OrderTests: XCTestCase {

    func fakeProduct(name: String, assets: [Asset]? = nil) -> PhotobookProduct {
        let photobookTemplate = PhotobookTemplate(id: 1, name: name, templateId: "HDBOOK-270x210", kiteId: "HDBOOK-270x210", coverSize: .zero, pageSize: .zero, spineTextRatio: 0.0, coverLayouts: [], layouts: [])
        let portraitLayoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.2, y: 0.05, width: 0.6, height: 0.9))
        let landscapeLayoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.2, width: 0.9, height: 0.6))
        let portraitLayout = Layout(id: 1, category: "layout", imageLayoutBox: portraitLayoutBox, textLayoutBox: nil, isDoubleLayout: false)
        let landscapeLayout = Layout(id: 1, category: "layout", imageLayoutBox: landscapeLayoutBox, textLayoutBox: nil, isDoubleLayout: false)
        return PhotobookProduct(template: photobookTemplate, assets: assets ?? [], coverLayouts: [portraitLayout, landscapeLayout], layouts: [portraitLayout, landscapeLayout])!
    }

    func fakeCost(totalCost: Decimal = 0.0) -> Cost {
        let lineItem = LineItem(id: 1, name: "item", cost: 20.0, formattedCost: "£20.00")
        let shippingMethod = ShippingMethod(id: 1, name: "Standard", shippingCostFormatted: "£4.99", totalCost: totalCost, totalCostFormatted: "£24.99", maxDeliveryTime: 10, minDeliveryTime: 3)
        
        return Cost(hash: 1, lineItems: [lineItem], shippingMethods: [shippingMethod], promoDiscount: nil, promoCodeInvalidReason: nil)
    }

    func testOrderIsFree_shouldBeFalseWithNoValidCost() {
        let order = Order()
        XCTAssertFalse(order.orderIsFree)
    }
    
    func testOrderIsFree_shouldBeFalseWithACost() {
        let order = Order()
        order.shippingMethod = 1
        
        let cost = fakeCost(totalCost: 4.99)
        cost.orderHash = order.hashValue
        order.cachedCost = cost
        XCTAssertFalse(order.orderIsFree)
    }

    func testOrderIsFree_shouldBeTrueWithoutACost() {
        let order = Order()
        order.shippingMethod = 1
        
        let cost = fakeCost()
        cost.orderHash = order.hashValue
        order.cachedCost = cost
        XCTAssertTrue(order.orderIsFree)
    }
    
    func testOrderDescription_shouldBeNilIfOrderHasNoProducts() {
        let order = Order()
        XCTAssertNil(order.orderDescription)
    }
    
    func testOrderDescription_shouldReturnSingleProductName() {
        let product = fakeProduct(name: "Landscape 270x210")
        let order = Order()
        order.products = [product]
        
        XCTAssertEqualOptional(order.orderDescription, "Landscape 270x210")
    }

    func testOrderDescription_shouldReturnFirstNameAndExtraProductCount() {
        var products = [PhotobookProduct]()
        for i in 1 ... 5 {
            products.append(fakeProduct(name: "Photobook #\(i)"))
        }
        let order = Order()
        order.products = products
        
        XCTAssertEqualOptional(order.orderDescription, "Photobook #1 & 4 others")
    }
    
    func testAssetsToUpload_shouldListAllAssetsWithoutRepeating() {
        var assets = [TestPhotosAsset]()
        for i in 1 ... 10 {
            let asset = TestPhotosAsset()
            asset.identifierStub = "Asset\(i)"
            assets.append(asset)
        }
        
        let product1 = fakeProduct(name: "Product 1", assets: Array(assets[0...2]))
        let product2 = fakeProduct(name: "Product 2", assets: Array(assets[2...5]))
        let product3 = fakeProduct(name: "Product 3", assets: Array(assets[2...9]))
        
        let order = Order()
        order.products = [product1, product2, product3]
        
        let assetsToUpload = order.assetsToUpload()
        XCTAssertEqual(assetsToUpload.count, 10)
    }
}
