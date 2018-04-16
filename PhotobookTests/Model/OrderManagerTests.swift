//
//  OrderManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 11/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class OrderManagerTests: XCTestCase {

    var productManager: ProductManager!
    let photosAsset = TestPhotosAsset(PHAsset(), albumIdentifier: "")
    
    override func setUp() {
        super.setUp()
        
        let photobookAPIManager = PhotobookAPIManager(apiClient: APIClient.shared, mockJsonFileName: "photobooks")
        productManager = ProductManager(apiManager: photobookAPIManager)
        
        let expectation = self.expectation(description: "Wait for product initialization")
        productManager.initialise(completion: { _ in
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 30)
        
        let validDictionary = ([
            "id": 10,
            "name": "210 x 210",
            "productTemplateId": "RPI_WRAP_210X210_SM",
            "pageHeight": 450.34,
            "spineTextRatio": 0.8,
            "aspectRatio": 1.38,
            "coverLayouts": [ 9, 10 ],
            "layouts": [ 10, 11, 12, 13 ]
            ]) as [String: AnyObject]
        
        guard let photobookTemplate = PhotobookTemplate.parse(validDictionary) else {
            XCTFail("Failed to parse photobook dictionary")
            return
        }
        
        guard
            let coverLayouts = productManager.coverLayouts(for: photobookTemplate),
            !coverLayouts.isEmpty,
            let layouts = productManager.layouts(for: photobookTemplate),
            !layouts.isEmpty
            else {
                XCTFail("ProductManager: Missing layouts for selected photobook")
                return
        }
        
        let product = PhotobookProduct(template: photobookTemplate, assets: [], coverLayouts: coverLayouts, layouts: layouts)
        productManager.currentProduct = product
        productManager.currentProduct?.productLayouts = [ProductLayout]()
        
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.01, y: 0.01, width: 0.5, height: 0.1))
        let layout = Layout(id: 1, category: "portrait", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: false)
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 12.0, height: 14.0)
        
        let productLayoutText = ProductLayoutText()
        productLayoutText.text = "Tests are groovy"
        
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: productLayoutText)

        productManager.currentProduct?.productLayouts.append(productLayout)
        
        OrderManager.shared.basketOrder.products = [product]
    }

    func testSaveBasketOrder() {
        let product = productManager.currentProduct!
        
        OrderManager.shared.saveBasketOrder()
        guard let unarchivedOrder = OrderManager.shared.loadBasketOrder() else {
            XCTFail("Decoding of product failed")
            return
        }
        
        XCTAssertEqual(unarchivedOrder.products.first!.template.id, product.template.id)
        XCTAssertEqual(unarchivedOrder.products.first!.template.name, product.template.name)
        XCTAssertEqual(unarchivedOrder.products.first!.template.aspectRatio, product.template.aspectRatio)
        XCTAssertEqual(unarchivedOrder.products.first!.template.layouts, product.template.layouts)
        XCTAssertEqual(unarchivedOrder.products.first!.template.coverLayouts, product.template.coverLayouts)

        XCTAssertEqual(unarchivedOrder.products.first!.coverColor, product.coverColor)
        XCTAssertEqual(unarchivedOrder.products.first!.pageColor, product.pageColor)

        XCTAssertEqual(unarchivedOrder.products.first!.productLayouts.first!.asset!.identifier, photosAsset.identifier)
        XCTAssertEqual(unarchivedOrder.products.first!.productLayouts.first!.asset!.size, photosAsset.size)
    }

}
