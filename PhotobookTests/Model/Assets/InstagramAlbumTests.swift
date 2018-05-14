//
//  InstagramAlbumTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 04/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import OAuthSwift
@testable import Photobook

class InstagramAlbumTests: XCTestCase {
    
    var instagramAlbum: InstagramAlbum!
    var instagramApiManager: TestInstagramApiManager!
    var keychainHandler: TestKeychainHandler!
    
    override func setUp() {
        super.setUp()
        
        instagramApiManager = TestInstagramApiManager()
        keychainHandler = TestKeychainHandler()
        
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
        
        if let asset = instagramAlbum.assets.first as? URLAsset {
            XCTAssertEqual(asset.images.count, 3)
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
