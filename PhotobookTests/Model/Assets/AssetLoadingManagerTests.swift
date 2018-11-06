//
//  AssetLoadingManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 29/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class AssetLoadingManagerTests: XCTestCase {
    
    let sut = AssetLoadingManager()
    
    var asset: PhotosAssetMock!
    
    override func setUp() {
        asset = PhotosAssetMock()
    }
    
    func testImageForAsset_returnsImageIfAssetProvidesIt() {
        let assetImage = UIImage(color: .red)
        asset.imageStub = assetImage

        let expectation = XCTestExpectation(description: "returns image")
        sut.image(for: asset, size: CGSize(width: 1.0, height: 1.0), loadThumbnailFirst: false, progressHandler: nil) { (image, error) in
            if assetImage == image {
                expectation.fulfill()
                return
            }
            XCTFail()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageForAsset_returnsErrorIfAssetFails() {
        asset.error = AssetLoadingException.notFound
        
        let expectation = XCTestExpectation(description: "returns error")
        sut.image(for: asset, size: CGSize(width: 1.0, height: 1.0), loadThumbnailFirst: false, progressHandler: nil) { (image, error) in
            if error != nil {
                expectation.fulfill()
                return
            }
            XCTFail()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageDataForAsset_returnsImageIfAssetProvidesIt() {
        let assetData = Data()
        asset.imageDataStub = assetData
        
        let expectation = XCTestExpectation(description: "returns image data")
        sut.imageData(for: asset, progressHandler: nil) { (data, ext, error) in
            if data != nil {
                expectation.fulfill()
                return
            }
            XCTFail()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageDataForAsset_returnsErrorIfAssetFails() {
        asset.error = AssetLoadingException.notFound
        
        let expectation = XCTestExpectation(description: "returns error")
        sut.imageData(for: asset, progressHandler: nil) { (data, ext, error) in
            if error != nil {
                expectation.fulfill()
                return
            }
            XCTFail()
        }
        wait(for: [expectation], timeout: 1.0)
    }

}
