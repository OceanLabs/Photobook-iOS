//
//  PhotosAssetTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 01/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import Photos
import MobileCoreServices
@testable import Photobook

class PhotosAssetTests: XCTestCase {
    
    let image = UIImage(color: .black, size: testSize)!
    let imageManager = PHImageManagerMock()
    let assetManager = AssetManagerMock()
    var phAsset: PHAssetMock!
    var photosAsset: PhotosAsset!
    
    override func setUp() {
        super.setUp()
        
        phAsset = PHAssetMock()
        phAsset.localIdentifierStub = "localID"
        assetManager.phAssetsStub = [phAsset]
        
        PhotosAsset.assetManager = assetManager
        
        photosAsset = PhotosAsset(phAsset, albumIdentifier: "album")
        photosAsset.imageManager = imageManager
    }
    
    func testPhotosAsset_canBeInitialised() {
        XCTAssertEqual(photosAsset.identifier, phAsset.localIdentifierStub)
        XCTAssertEqual(photosAsset.albumIdentifier, "album")
        XCTAssertTrue(photosAsset.photosAsset === phAsset)
    }
    
    func testSettingAssetSetsIdentifier() {
        phAsset.localIdentifierStub = "localID2"
        photosAsset.photosAsset = phAsset
        XCTAssertEqual(photosAsset.identifier, phAsset.localIdentifier)
    }
    
    func testReturnsDate() {
        let date = Date()
        phAsset.dateStub = date
        XCTAssertEqual(photosAsset.date, date)
    }
    
    func testImage_returnRightSize() {
        phAsset.widthStub = 3000
        phAsset.heightStub = 2000
        
        let expectation = XCTestExpectation(description: "returns right size")
        photosAsset.image(size: CGSize(width: 500.0, height: 500.0), loadThumbnailFirst: false, progressHandler: nil) { (image, _) in
            guard let image = image,
                image.size.width ==~ 750 * UIScreen.main.usableScreenScale(),
                image.size.height ==~ 500 * UIScreen.main.usableScreenScale()
                else {
                    XCTFail()
                    return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldFailIfImageDataIsMissing() {
        imageManager.imageData = nil
        imageManager.dataUti = kUTTypePNG as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData == nil, case .unsupported = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldFailIfDataUtiIsMissing() {
        imageManager.imageData = Data()
        imageManager.dataUti = nil
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData == nil, case .unsupported = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldNotWorkWithNonImageTypes() {
        phAsset.mediaTypeStub = .video
        
        // Doesn't matter what we define as long as it is non-nil
        
        imageManager.imageData = image.pngData()
        imageManager.dataUti = kUTTypePNG as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData == nil, case .unsupported = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldWorkWithPNG() {
        imageManager.imageData = Data()
        imageManager.dataUti = kUTTypePNG as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData != nil, case .png = fileExtension  else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldWorkWithJPEG() {
        imageManager.imageData = Data()
        imageManager.dataUti = kUTTypeJPEG as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData != nil, case .jpg = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldWorkWithGIF() {
        imageManager.imageData = Data()
        imageManager.dataUti = kUTTypeGIF as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData != nil, case .gif = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldWorkWithSomethingConversibleToImage() {
        imageManager.imageData = image.pngData()
        imageManager.dataUti = kUTTypeBMP as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData != nil, case .jpg = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldNotWorkWithNonImageData() {
        imageManager.imageData = Data()
        imageManager.dataUti = kUTTypePDF as String?
        
        let expectation = XCTestExpectation(description: "returns image data and extension")
        
        photosAsset.imageData(progressHandler: nil) { (imageData, fileExtension, error) in
            guard imageData == nil, case .unsupported = fileExtension else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPhotosAssetsFromAssets_returnsAssets() {
        var assets = [Asset]()
        for _ in 0 ..< 10 {
            assets.append(PhotosAssetMock())
        }
        let resultingAssets = PhotosAsset.photosAssets(from: assets)
        XCTAssertEqual(resultingAssets.count, assets.count)
    }
    
    func testPhotosAssetsFromAssets_shouldFilterOutNonPhotosAssets() {
        var assets = [Asset]()
        for i in 0 ..< 10 {
            if i % 2 == 0 {
                assets.append(PhotosAssetMock())
            } else {
                let urlAsset = URLAsset(URL(string: testUrlString)!, size: testSize)
                assets.append(urlAsset)
            }
        }
        let resultingAssets = PhotosAsset.photosAssets(from: assets)
        XCTAssertEqual(resultingAssets.count, assets.count / 2)
    }
    
    func testAssetsFromPhotosAssets_returnsAssets() {
        var assets = [PHAssetMock]()
        for _ in 0 ..< 10 {
            assets.append(PHAssetMock())
        }
        let resultingAssets = PhotosAsset.assets(from: assets, albumId: "album")
        XCTAssertEqual(resultingAssets.count, assets.count)
    }
    
    func testPhotosAsset_canBeArchivedAndUnarchived() {
        photosAsset.uploadUrl = testUrlString
        
        guard let data = try? PropertyListEncoder().encode(photosAsset) else {
            XCTFail("Should encode the PhotosAsset to data")
            return
        }
        guard archiveObject(data, to: "PhotosAssetTests.dat") else {
            XCTFail("Should save the PhotosAsset data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "PhotosAssetTests.dat") as? Data else {
            XCTFail("Should unarchive the PhotosAsset as Data")
            return
        }
        guard let unarchivedPhotosAsset = try? PropertyListDecoder().decode(PhotosAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the PhotosAsset")
            return
        }

        XCTAssertEqualOptional(unarchivedPhotosAsset.albumIdentifier, photosAsset.albumIdentifier)
        XCTAssertEqualOptional(unarchivedPhotosAsset.identifier, photosAsset.identifier)
        XCTAssertEqualOptional(unarchivedPhotosAsset.uploadUrl, photosAsset.uploadUrl)
    }
}
