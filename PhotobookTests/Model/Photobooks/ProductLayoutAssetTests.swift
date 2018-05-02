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

    var photosAsset: PhotosAsset = TestPhotosAsset(PHAsset())
        
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
        XCTAssertTrue(transform ==~ originalTransform, "The decoded transform must match the original transform")
        
        XCTAssertTrue(unarchivedProductLayoutAsset.containerSize.width == originalContainerSize.width
            && unarchivedProductLayoutAsset.containerSize.height == originalContainerSize.height, "The decoded container size must match the original size")
    }
    
    // MARK: ContainerSize didSet
    func testContainerSize_fitsAssetIfFirstTime() {
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        let expectedTransform = CGAffineTransform(a: 0.05, b: 0.0, c: 0.0, d: 0.05, tx: 0.0, ty: 0.0)
        XCTAssertTrue(productLayoutAsset.transform ==~ expectedTransform)
    }
    
    func testContainerSize_doesNotFitAssetIfSecondTime() {
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        productLayoutAsset.transform = CGAffineTransform.identity
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        
        let expectedTransform = CGAffineTransform(a: 0.05, b: 0.0, c: 0.0, d: 0.05, tx: 0.0, ty: 0.0)
        XCTAssertFalse(productLayoutAsset.transform ==~ expectedTransform)
    }

    func testContainerSize_fitsAssetIfShouldFitAssetIsTrue() {
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        productLayoutAsset.transform = CGAffineTransform.identity
        productLayoutAsset.shouldFitAsset = true
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)

        let expectedTransform = CGAffineTransform(a: 0.05, b: 0.0, c: 0.0, d: 0.05, tx: 0.0, ty: 0.0)
        XCTAssertTrue(productLayoutAsset.transform ==~ expectedTransform)
    }
    
    func testContainerSize_adjustsTransformWithAfterSizeChangeToSmallerContainer() {
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        productLayoutAsset.containerSize = CGSize(width: 110.0, height: 80.0)
        
        let expectedTransform = CGAffineTransform(a: 0.046, b: 0.0, c: 0.0, d: 0.046, tx: 0.0, ty: 0.0)
        XCTAssertTrue(productLayoutAsset.transform ==~ expectedTransform)
    }
    
    func testContainerSize_adjustsTransformWithAfterSizeChangeToBiggerContainer() {
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        productLayoutAsset.containerSize = CGSize(width: 230.0, height: 300.0)
        
        let expectedTransform = CGAffineTransform(a: 0.15, b: 0.0, c: 0.0, d: 0.15, tx: 0.0, ty: 0.0)
        XCTAssertTrue(productLayoutAsset.transform ==~ expectedTransform)
    }

    // MARK: - Shallow copy
    func testShallowCopy() {
        let image = UIImage()
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 120.0, height: 100.0)
        productLayoutAsset.currentIdentifier = "1"
        productLayoutAsset.currentImage = image
        
        let productLayoutAssetCopy = productLayoutAsset.shallowCopy()
        XCTAssertTrue(productLayoutAssetCopy.asset != nil &&
            productLayoutAssetCopy.currentImage != nil &&
            productLayoutAssetCopy.currentIdentifier != nil &&
            productLayoutAssetCopy.asset! == productLayoutAsset.asset! &&
            productLayoutAssetCopy.containerSize == productLayoutAsset.containerSize &&
            productLayoutAssetCopy.transform == productLayoutAsset.transform &&
            productLayoutAssetCopy.currentIdentifier! == productLayoutAsset.currentIdentifier! &&
            productLayoutAssetCopy.currentImage! == productLayoutAsset.currentImage!)
    }
}
