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

class ErrorMock: LocalizedError {
    var errorDescription: String? { return "Test Error" }
}

class FacebookAlbumTests: XCTestCase {
    
    var facebookAlbum: FacebookAlbum!
    var facebookApiManager: FacebookApiManagerMock!

    override func setUp() {
        super.setUp()
        
        facebookAlbum = FacebookAlbum(identifier: "id101", localizedName: "albumName", numberOfAssets: 12, coverPhotoUrl: testUrl)
        facebookApiManager = FacebookApiManagerMock()
        facebookAlbum.facebookManager = facebookApiManager
    }

    func testInitialisation() {
        XCTAssertEqual(facebookAlbum.identifier, "id101")
        XCTAssertEqual(facebookAlbum.localizedName, "albumName")
        XCTAssertEqual(facebookAlbum.numberOfAssets, 12)
        XCTAssertEqual(facebookAlbum.coverPhotoUrl, testUrl)
    }

    func testLoadAssets_shouldReturnErrorIfApiFails() {
        facebookApiManager.error = ErrorMock()
        facebookAlbum.loadAssets { (error) in XCTAssertNotNil(error) }
    }
 
    func testLoadAssets_shouldReturnErrorIfResultIsNil() {
        facebookAlbum.loadAssets { (error) in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldReturnErrorIfResultIsNotDictionary() {
        facebookApiManager.result = ["An array", "With strings"]
        facebookAlbum.loadAssets { (error) in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldNotParseImageDataWithoutIdOrImages() {
        let testData = ["data": [
            ["id": "1", "images": [["source": testUrlString, "width": 400, "height": 200]]],
            ["id": "2"],
            ["id": "3", "images": [["source": testUrlString, "width": 600, "height": 400]]],
            ["images": [["source": testUrlString, "width": 700, "height": 500]]]
            ]]

        facebookApiManager.result = testData
        facebookAlbum.loadAssets { (error) in
            XCTAssertEqual(self.facebookAlbum.assets.count, 2)
            XCTAssertTrue(self.facebookAlbum.assets.contains { $0.identifier == "1"})
            XCTAssertTrue(self.facebookAlbum.assets.contains { $0.identifier == "3"})
        }
    }
    
    func testLoadAssets_shouldNotParseImageDataWithoutSourceWidthOrHeight() {
        let testData = ["data": [
            ["id": "1", "images": [["width": 400, "height": 200]]],
            ["id": "2", "images": [["source": testUrlString, "height": 300]]],
            ["id": "3", "images": [["source": testUrlString, "width": 600, "height": 400]]],
            ["id": "4", "images": [["source": testUrlString, "width": 700]]]
            ]]

        facebookApiManager.result = testData
        facebookAlbum.loadAssets { (error) in
            XCTAssertEqual(self.facebookAlbum.assets.count, 1)
            self.XCTAssertEqualOptional(self.facebookAlbum.assets.first?.identifier, "3")
        }
    }
    
    func testLoadNextBatchOfAssets_shouldDoNothingIfThereIsNoMoreAssetsToRequest() {
        let testData = ["data": [["id": "1", "images": [["width": 400, "height": 200]]]]]

        facebookApiManager.result = testData
        
        var called: Bool = false
        facebookAlbum.loadNextBatchOfAssets { _ in called = true }
        
        XCTAssertFalse(called)
    }
    
    func testLoadNextBatchOfAlbums_shouldPerformRequestWithProvidedNextUrl() {
        var testData: [String : Any] = ["data": [["id": "1", "images": [["width": 400, "height": 200]]]],
                                        "paging": ["next": "yes", "cursors": ["after" : "afterText"]]]

        facebookApiManager.result = testData
        facebookAlbum.loadAssets { _ in }
        XCTAssertTrue(facebookAlbum.hasMoreAssetsToLoad)
        
        testData["paging"] = nil
        facebookApiManager.result = testData
        facebookAlbum.loadNextBatchOfAssets { _ in }
        XCTAssertTrue(facebookApiManager.lastPath != nil && facebookApiManager.lastPath!.contains("afterText"))
        XCTAssertFalse(facebookAlbum.hasMoreAssetsToLoad)
    }

    func testFacebookAlbum_canBeArchivedAndUnarchived() {
        guard let data = try? PropertyListEncoder().encode(facebookAlbum) else {
            XCTFail("Should encode the FacebookAlbum data")
            return
        }
        guard archiveObject(data, to: "FacebookAlbumTests.dat") else {
            XCTFail("Should save the FacebookAlbum data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "FacebookAlbumTests.dat") as? Data else {
            XCTFail("Should unarchive the FacebookAlbum as Data")
            return
        }
        guard let unarchivedFacebookAlbum = try? PropertyListDecoder().decode(FacebookAlbum.self, from: unarchivedData) else {
            XCTFail("Should decode the PhotosAsset")
            return
        }
        
        XCTAssertEqualOptional(unarchivedFacebookAlbum.identifier, facebookAlbum.identifier)
        XCTAssertEqualOptional(unarchivedFacebookAlbum.localizedName, facebookAlbum.localizedName)
        XCTAssertEqualOptional(unarchivedFacebookAlbum.numberOfAssets, facebookAlbum.numberOfAssets)
        XCTAssertEqualOptional(unarchivedFacebookAlbum.coverPhotoUrl, facebookAlbum.coverPhotoUrl)
    }

    func testCoverAsset() {
        facebookAlbum.coverAsset { (asset) in
            guard let urlAsset = asset as? URLAsset else {
                XCTFail()
                return
            }
            XCTAssertEqual(urlAsset.identifier, testUrl.absoluteString)
            XCTAssertEqual(urlAsset.albumIdentifier, self.facebookAlbum.identifier)
            self.XCTAssertEqualOptional(urlAsset.images.first?.url, testUrl)
        }
    }
}
