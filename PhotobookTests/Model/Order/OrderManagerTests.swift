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
    
    let apiClient = APIClientMock()
    lazy var photobookAPIManager = PhotobookAPIManager(apiClient: apiClient)

    override func setUp() {
        super.setUp()
        
        apiClient.response = JSON.parse(file: "photobooks")
        productManager = ProductManager(apiManager: photobookAPIManager)
        productManager.initialise(completion: nil)
        
        _ = productManager.setCurrentProduct(with: productManager.products!.first!, assets: [])
        
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
        
        OrderManager.shared.basketOrder.products = [productManager.currentProduct!]
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
