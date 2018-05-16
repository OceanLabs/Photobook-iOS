//
//  ImageAssetTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class ImageAssetTests: XCTestCase {
    
    func testSize() {
        let image = UIImage(color: .red)!
        let imageAsset = ImageAsset(image: image)
        
        XCTAssertEqualOptional(imageAsset.size, CGSize(width: 1.0, height: 1.0))
    }
    
    func testImageAssetImage_canBeArchivedAndUnarchived() {
        
        let image = UIImage(color: .red)!
        let date = Date()
        let imageAsset = ImageAsset(image: image, date: date)
        
        if !archiveObject(imageAsset, to: "ImageAssetTests.dat") {
            print("Could not save imageAsset")
        }
        let imageAssetUnarchived = unarchiveObject(from: "ImageAssetTests.dat") as? ImageAsset
        
        XCTAssertEqualOptional(imageAssetUnarchived?.image.size, image.size)
        XCTAssertEqualOptional(imageAssetUnarchived?.date, date)
    }

    func testImageAssetImage_shouldNotArchiveImageWithExistingUrl() {
        
        let image = UIImage(color: .red)!
        let date = Date()
        let imageAsset = ImageAsset(image: image, date: date)
        imageAsset.uploadUrl = testUrlString
        
        if !archiveObject(imageAsset, to: "ImageAssetTests.dat") {
            print("Could not save imageAsset")
        }
        let imageAssetUnarchived = unarchiveObject(from: "ImageAssetTests.dat") as? ImageAsset
        
        XCTAssertNil(imageAssetUnarchived?.image.size)
    }
    
    func testImage_returnsImage() {
        let image = UIImage(color: .red)!
        let imageAsset = ImageAsset(image: image)

        imageAsset.image(size: .zero, loadThumbnailFirst: false, progressHandler: nil) { (imageResult, _) in
            XCTAssertNotNil(imageResult)
        }
    }
    
    func testImageData_returnsData() {
        let image = UIImage(color: .red)!
        let imageAsset = ImageAsset(image: image)
        
        imageAsset.imageData(progressHandler: nil) { (data, fileExtension, _) in
            XCTAssertNotNil(data)
            XCTAssertEqual(fileExtension, .jpg)
        }
    }
}
