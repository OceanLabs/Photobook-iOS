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

class OrderTests: XCTestCase {

    func fakeProduct(name: String, assets: [Asset]? = nil) -> PhotobookProduct {
        let photobookTemplate = PhotobookTemplate(id: 1, name: name, templateId: "HDBOOK-270x210", kiteId: "HDBOOK-270x210", coverSize: .zero, pageSize: .zero, spineTextRatio: 0.0, coverLayouts: [], layouts: [], pageBleed: 8.5)
        let portraitLayoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.2, y: 0.05, width: 0.6, height: 0.9))
        let landscapeLayoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.2, width: 0.9, height: 0.6))
        let portraitLayout = Layout(id: 1, category: "layout", imageLayoutBox: portraitLayoutBox, textLayoutBox: nil, isDoubleLayout: false)
        let landscapeLayout = Layout(id: 1, category: "layout", imageLayoutBox: landscapeLayoutBox, textLayoutBox: nil, isDoubleLayout: false)
        return PhotobookProduct(template: photobookTemplate, assets: assets ?? [], coverLayouts: [portraitLayout, landscapeLayout], layouts: [portraitLayout, landscapeLayout])!
    }

    func fakeCost(totalCost: Decimal = 0.0) -> Cost {
        let lineItem = LineItem(templateId: "hdbook_127x127", name: "item", price: Price(currencyCode: "GBP", value: 20), identifier: "")
        
        return Cost(hash: 1, lineItems: [lineItem], totalShippingPrice: Price(currencyCode: "GBP", value: 7), total: Price(currencyCode: "GBP", value: totalCost), promoDiscount: nil, promoCodeInvalidReason: nil)
    }

    func testOrderIsFree_shouldBeFalseWithNoValidCost() {
        let order = Order()
        XCTAssertFalse(order.orderIsFree)
    }
    
    func testOrderIsFree_shouldBeFalseWithACost() {
        let order = Order()
        
        let cost = fakeCost(totalCost: 4.99)
        cost.orderHash = order.hashValue
        order.setCachedCost(cost)
        XCTAssertFalse(order.orderIsFree)
    }

    func testOrderIsFree_shouldBeTrueWithoutACost() {
        let order = Order()
        
        let cost = fakeCost()
        cost.orderHash = order.hashValue
        order.setCachedCost(cost)
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
        var assets = [PhotosAssetMock]()
        for i in 1 ... 10 {
            let asset = PhotosAssetMock()
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
