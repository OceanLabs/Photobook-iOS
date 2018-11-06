//
//  CustomAssetTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 29/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CustomAssetDataSource: NSObject, AssetDataSource {
    
    var imageStub: UIImage?
    var imageDataStub: Data?
    var error: Error?
    
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        completionHandler(imageStub, error)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        completionHandler(imageDataStub, .jpg, error)
    }
    
    func encode(with aCoder: NSCoder) {
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        self.init()
    }
}

class CustomAssetTests: XCTestCase {

    var sut: CustomAsset!
    let dataSource = CustomAssetDataSource()
    let size = CGSize(width: 10.0, height: 5.0)
    let date = Date()
    
    override func setUp() {
        super.setUp()
        
        sut = CustomAsset(dataSource: dataSource, size: size, date: date)
    }
    
    func testCustomAsset_canBeInitialised() {
        XCTAssertEqual(sut.size, size)
        XCTAssertEqual(sut.date, date)
    }
    
    func testImageSize_returnsDataSourceImage() {
        let imageStub = UIImage(color: .red)
        dataSource.imageStub = imageStub
        sut.image(size: CGSize(width: 50.0, height: 40.0), loadThumbnailFirst: false, progressHandler: nil) { (image, error) in
            self.XCTAssertEqualOptional(image, imageStub)
        }
    }

    func testImageSize_returnsError() {
        dataSource.error = AssetLoadingException.notFound
        sut.image(size: CGSize(width: 50.0, height: 40.0), loadThumbnailFirst: false, progressHandler: nil) { (image, error) in
            XCTAssertNotNil(error)
        }
    }

    func testImageData_returnsDataSourceImageData() {
        let imageDataStub = Data()
        dataSource.imageDataStub = imageDataStub
        sut.imageData(progressHandler: nil) { (imageData, extension, error) in
            self.XCTAssertEqualOptional(imageData, imageDataStub)
        }
    }
    
    func testImageData_returnsError() {
        dataSource.error = AssetLoadingException.notFound
        sut.imageData(progressHandler: nil) { (imageData, extension, error) in
            XCTAssertNotNil(error)
        }
    }

    func testPhotosAsset_canBeArchivedAndUnarchived() {
        sut.uploadUrl = testUrlString
        
        guard let data = try? PropertyListEncoder().encode(sut) else {
            XCTFail("Should encode the CustomAsset to data")
            return
        }
        guard archiveObject(data, to: "CustomAssetTests.dat") else {
            XCTFail("Should save the CustomAsset data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "CustomAssetTests.dat") as? Data else {
            XCTFail("Should unarchive the CustomAsset as Data")
            return
        }
        guard let unarchivedCustomAsset = try? PropertyListDecoder().decode(CustomAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the CustomAsset")
            return
        }
        
        XCTAssertEqualOptional(unarchivedCustomAsset.identifier, sut.identifier)
        XCTAssertEqualOptional(unarchivedCustomAsset.uploadUrl, sut.uploadUrl)
        XCTAssertEqualOptional(unarchivedCustomAsset.size, sut.size)
        XCTAssertEqualOptional(unarchivedCustomAsset.date, sut.date)
    }
}
