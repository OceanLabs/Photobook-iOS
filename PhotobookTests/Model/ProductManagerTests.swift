//
//  ProductManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 11/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class ProductManagerTests: XCTestCase {

    var productManager: ProductManager!
    let photosAsset = TestPhotosAsset(PHAsset(), albumIdentifier: "")
    
    override func setUp() {
        super.setUp()
        
        productManager = ProductManager()
        
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
        
        productManager.currentProduct = PhotobookProduct(template: photobookTemplate, addedAssets: [])
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
    }

    func testSaveUserPhotobook() {
        productManager.currentProduct?.saveUserPhotobook()
        
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: productManager.currentProduct!.storageFile) as? Data else {
            XCTFail("Failed to unarchive product")
            return
        }
        
        guard let unarchivedProduct = try? PropertyListDecoder().decode(PhotobookBackup.self, from: unarchivedData) else {
            XCTFail("Decoding of product failed")
            return
        }
        
        XCTAssertEqual(unarchivedProduct.template.id, productManager.currentProduct!.template.id)
        XCTAssertEqual(unarchivedProduct.template.name, productManager.currentProduct!.template.name)
        XCTAssertEqual(unarchivedProduct.template.aspectRatio, productManager.currentProduct!.template.aspectRatio)
        XCTAssertEqual(unarchivedProduct.template.layouts, productManager.currentProduct!.template.layouts)
        XCTAssertEqual(unarchivedProduct.template.coverLayouts, productManager.currentProduct!.template.coverLayouts)

        XCTAssertEqual(unarchivedProduct.coverColor, productManager.currentProduct!.coverColor)
        XCTAssertEqual(unarchivedProduct.pageColor, productManager.currentProduct!.pageColor)

        XCTAssertEqual(unarchivedProduct.productLayouts.first!.asset!.identifier, photosAsset.identifier)
        XCTAssertEqual(unarchivedProduct.productLayouts.first!.asset!.size, photosAsset.size)
    }

}
