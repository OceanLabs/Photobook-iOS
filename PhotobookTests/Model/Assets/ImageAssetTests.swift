//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        
        XCTAssertEqualOptional(unarchivedImageAsset.image?.size, image.size)
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

        XCTAssertNil(unarchivedImageAsset.image)
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
            XCTAssertEqual(fileExtension.string(), AssetDataFileExtension.jpg.string())
        }
    }
}
