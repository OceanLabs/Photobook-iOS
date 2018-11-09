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
import OAuthSwift
@testable import Photobook_App
@testable import Photobook

class InstagramAlbumTests: XCTestCase {
    
    var instagramAlbum: InstagramAlbum!
    var instagramApiManager: InstagramApiManagerMock!
    var keychainHandler: KeychainHandlerMock!
    
    override func setUp() {
        super.setUp()
        
        instagramApiManager = InstagramApiManagerMock()
        keychainHandler = KeychainHandlerMock()
        
        instagramAlbum = InstagramAlbum()
        instagramAlbum.instagramApiManager = instagramApiManager
        instagramAlbum.keychainHandler = keychainHandler
    }

    func testLoadAssets_shouldFailWithoutATokenKey() {        
        instagramAlbum.loadAssets { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldFailIfApiFails() {
        keychainHandler.tokenKey = "masterKey"
        
        let error = OAuthSwiftError.serverError(message: "Something went wrong")
        instagramApiManager.error = error
        instagramAlbum.loadAssets { (error) in
            self.XCTAssertEqualOptional(error?.localizedDescription, error?.localizedDescription)
        }
    }

    func testLoadAssets_shouldUpdateTokenKeyIfProvidedByApi() {
        keychainHandler.tokenKey = "masterKey"
        let credential = OAuthSwiftCredential(consumerKey: "", consumerSecret: "")
        credential.oauthToken = "newKey"
        
        instagramApiManager.credential = credential
        instagramAlbum.loadAssets { _ in }

        XCTAssertEqualOptional(keychainHandler?.tokenKey, "newKey")
    }
    
    func testLoadAssets_shouldReturnErrorIfDataIsMissing() {
        keychainHandler.tokenKey = "masterKey"
        
        instagramApiManager.data = [ "bad object" ]
        instagramAlbum.loadAssets { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldParseCarousel() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["id": "1", "carousel_media": [
                        ["images": ["standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString]
                    ]]]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        XCTAssertEqual(instagramAlbum.assets.count, 1)
    }

    func testLoadAssets_shouldNotParseCarouselIfImagesAreMissing() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["id": "1", "carousel_media": [["fake" : "news"]]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        XCTAssertEqual(instagramAlbum.assets.count, 0)
    }

    func testLoadAssets_shouldParseImages() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["id": "1", "images": ["standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString]
                    ]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        XCTAssertEqual(instagramAlbum.assets.count, 1)
    }

    func testLoadAssets_shouldParseIntoUrlAssetImages() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["id": "1", "images": [ "standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString], "low_resolution": ["width": 10.0, "height": 10.0,  "url": testUrlString], "thumbnail": ["width": 40.0, "height": 40.0, "url": testUrlString]
                ]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        
        if let photobookAsset = instagramAlbum.assets.first, let urlAsset = photobookAsset.asset as? URLAsset {
            XCTAssertEqual(urlAsset.images.count, 3)
        } else {
            XCTFail()
        }
    }
    
    func testLoadAssets_shouldNotParseIfIdIsMissing() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["images": [ "standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString], "low_resolution": ["width": 10.0, "height": 10.0,  "url": testUrlString], "thumbnail": ["width": 40.0, "height": 40.0, "url": testUrlString]
                ]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        
        XCTAssertEqual(instagramAlbum.assets.count, 0)
    }

    func testLoadAssets_shouldDoNothingIfThereIsNoMoreAssetsToRequest() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "info" : "" ],
            "data": [["id": "1", "images": ["standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString]
                ]]]
        ]
        
        instagramApiManager.data = dataObject
        
        var called: Bool = false
        instagramAlbum.loadNextBatchOfAssets { _ in called = true }
        
        XCTAssertFalse(called)
    }
    
    func testLoadAssets_shouldPerformRequestWithProvidedNextUrl() {
        keychainHandler.tokenKey = "masterKey"
        
        let dataObject: [String: Any] = [
            "pagination": [ "next_url" : testUrlString ],
            "data": [["id": "1", "images": ["standard_resolution": ["width": 100.0, "height": 100.0, "url": testUrlString]
                ]]]
        ]
        
        instagramApiManager.data = dataObject
        instagramAlbum.loadAssets { _ in }
        instagramAlbum.loadNextBatchOfAssets { _ in }
        XCTAssertTrue(instagramApiManager.lastUrl != nil && instagramApiManager.lastUrl!.hasPrefix(testUrlString))
    }
}
