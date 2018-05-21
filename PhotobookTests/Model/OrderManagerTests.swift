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
    let photosAsset = TestPhotosAsset()
    
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
            "kiteId": "HDBOOK-127x127",
            "displayName": "Square 127x127",
            "templateId": "hdbook_127x127",
            "spineTextRatio": 0.87,
            "coverLayouts": [ 9, 10 ],
            "layouts": [ 10, 11, 12, 13 ],
            "variants": [
                [
                    "minPages": 20,
                    "maxPages": 100,
                    "coverSize": [
                        "mm": [
                            "height": 127,
                            "width": 129
                        ]
                    ],
                    "size": [
                        "mm": [
                            "height": 121,
                            "width": 216
                        ]
                    ]
                ]
            ]
        ]) as [String: AnyObject]
        
        guard let photobookTemplate = PhotobookTemplate.parse(validDictionary) else {
            XCTFail("Failed to parse photobook dictionary")
            return
        }
        
        guard let product = productManager.setCurrentProduct(with: photobookTemplate, assets: []) else {
            XCTFail("Failed to initialise the Photobook product")
            return
        }
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
        
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/BasketOrder.dat")) as? Data else {
            XCTFail("Decoding of product failed")
            return
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            XCTFail("Decoding of product failed")
            return
        }
        
        XCTAssertEqual(unarchivedOrder.products.first!.template.id, product.template.id)
        XCTAssertEqual(unarchivedOrder.products.first!.template.name, product.template.name)
        XCTAssertEqual(unarchivedOrder.products.first!.template.coverAspectRatio, product.template.coverAspectRatio)
        XCTAssertEqual(unarchivedOrder.products.first!.template.pageAspectRatio, product.template.pageAspectRatio)
        XCTAssertEqual(unarchivedOrder.products.first!.template.layouts, product.template.layouts)
        XCTAssertEqual(unarchivedOrder.products.first!.template.coverLayouts, product.template.coverLayouts)

        XCTAssertEqual(unarchivedOrder.products.first!.coverColor, product.coverColor)
        XCTAssertEqual(unarchivedOrder.products.first!.pageColor, product.pageColor)

        XCTAssertEqual(unarchivedOrder.products.first!.productLayouts.first!.asset!.identifier, photosAsset.identifier)
        XCTAssertEqual(unarchivedOrder.products.first!.productLayouts.first!.asset!.size, photosAsset.size)
    }

}
