//
//  ProductLayoutAssetTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 11/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class ProductLayoutAssetTests: XCTestCase {
    
    let tempFile: String = NSTemporaryDirectory() + "tempProductLayoutAsset.dat"

    var photosAsset: PhotosAsset = TestPhotosAsset(PHAsset(), collection: PHAssetCollection())
        
    func testProductLayoutAsset_canBeEncodedAndDecoded() {
        
        var originalTransform = CGAffineTransform.identity.rotated(by: 1.2)
        let originalContainerSize = CGSize(width: 200.0, height: 300.0)
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.transform = originalTransform
        productLayoutAsset.containerSize = originalContainerSize
        
        originalTransform = productLayoutAsset.transform
        
        guard let data = try? PropertyListEncoder().encode(productLayoutAsset) else {
            XCTFail("Should encode the ProductLayoutAsset to data")
            return
        }
        guard NSKeyedArchiver.archiveRootObject(data, toFile: tempFile) else {
            XCTFail("Should save the ProductLayoutAsset data to disk")
            return
        }
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: tempFile) as? Data else {
            XCTFail("Should unarchive the ProductLayoutAsset as Data")
            return
        }
        guard let unarchivedProductLayoutAsset = try? PropertyListDecoder().decode(ProductLayoutAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the ProductLayoutAsset")
            return
        }
        
        let asset = unarchivedProductLayoutAsset.asset as? PhotosAsset
        XCTAssertNotNil(asset, "The asset should be a PhotosAsset")
        
        let transform = unarchivedProductLayoutAsset.transform
        XCTAssertTrue(transform == originalTransform, "The decoded transform must match the original transform")
        
        XCTAssertTrue(unarchivedProductLayoutAsset.containerSize.width == originalContainerSize.width
            && unarchivedProductLayoutAsset.containerSize.height == originalContainerSize.height, "The decoded container size must match the original size")
    }
    
}
