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
        
        guard let data = try? PropertyListEncoder().encode(imageAsset) else {
            XCTFail("Should encode the ImageAsset to data")
            return
        }
        guard archiveObject(data, to: "ImageAssetTests.dat") else {
            XCTFail("Should save the ImageAsset data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "ImageAssetTests.dat") as? Data else {
            XCTFail("Should unarchive the ImageAsset as Data")
            return
        }
        guard let unarchivedImageAsset = try? PropertyListDecoder().decode(ImageAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the ImageAsset")
            return
        }
        
        XCTAssertEqualOptional(unarchivedImageAsset.image.size, image.size)
        XCTAssertEqualOptional(unarchivedImageAsset.date, date)
    }

    func testImageAssetImage_shouldNotArchiveImageWithExistingUrl() {
        
        let image = UIImage(color: .red)!
        let date = Date()
        let imageAsset = ImageAsset(image: image, date: date)
        imageAsset.uploadUrl = testUrlString
        
        guard let data = try? PropertyListEncoder().encode(imageAsset) else {
            XCTFail("Should encode the ImageAsset to data")
            return
        }
        guard archiveObject(data, to: "ImageAssetTests.dat") else {
            XCTFail("Should save the ImageAsset data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "ImageAssetTests.dat") as? Data else {
            XCTFail("Should unarchive the ImageAsset as Data")
            return
        }
        guard let unarchivedImageAsset = try? PropertyListDecoder().decode(ImageAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the ImageAsset")
            return
        }

        XCTAssertEqual(unarchivedImageAsset.image.size, CGSize.zero)
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
