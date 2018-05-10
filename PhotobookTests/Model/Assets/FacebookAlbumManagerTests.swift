//
//  FacebookAlbumManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 04/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class FacebookAlbumManagerTests: XCTestCase {
    
    var facebookAlbumManager: FacebookAlbumManager!
    var facebookApiManager: TestFacebookApiManager!
    
    override func setUp() {
        super.setUp()
        
        facebookAlbumManager = FacebookAlbumManager()
        facebookApiManager = TestFacebookApiManager()
        facebookAlbumManager.facebookManager = facebookApiManager
    }
    
    func testLoadAssets_shouldFailWithoutATokenKey() {
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }

    func testLoadAlbums_shouldCallCompletionIfThereAreAlbumsAlreadyLoaded() {
        facebookApiManager.accessToken = "ClownKey"
        var called = false
        
        let album = PhotosAlbum(TestPHAssetCollection())
        facebookAlbumManager.albums = [album]
        facebookAlbumManager.loadAlbums { error in
            called = true
            XCTAssertNil(error)
        }
        XCTAssertTrue(called)
    }
    
    func testLoadAlbums_shouldReturnErrorIfApiFails() {
        facebookApiManager.accessToken = "ClownKey"
        facebookApiManager.error = TestError()
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAlbums_shouldReturnErrorIfResultIsNil() {
        facebookApiManager.accessToken = "ClownKey"
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAlbums_shouldReturnErrorIfResultIsNotDictionary() {
        facebookApiManager.accessToken = "ClownKey"
        facebookApiManager.result = ["An array", "With strings"]
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldNotParseImageDataWithoutRequiredFields() {
        facebookApiManager.accessToken = "ClownKey"
        let testData = ["data": [
            ["id": "1", "name": "Clown Photos", "cover_photo": ["id": "cover_1"]],
            ["id": "2", "name": "Massive Fiesta", "count": 3, "cover_photo": ["id": "cover_2"]],
            ["id": "3", "count": 1, "cover_photo": ["id": "cover_3"]],
            ["name": "Friday Clowning", "count": 1, "cover_photo": ["id": "cover_4"]],
            ["id": "5", "name": "Friday Clowning", "count": 1 ],
            ["id": "6", "name": "Friday Clowning", "count": 1, "cover_photo": ["id": "cover_6"]],
            ]]
        
        // Should only parse 2 & 6
        facebookApiManager.result = testData
        facebookAlbumManager.loadAlbums { (error) in
            XCTAssertEqual(self.facebookAlbumManager.albums.count, 2)
            XCTAssertTrue(self.facebookAlbumManager.albums.contains { $0.identifier == "2"})
            XCTAssertTrue(self.facebookAlbumManager.albums.contains { $0.identifier == "6"})
        }
    }
    
    func testLoadNextBatchOfAlbums_shouldDoNothingIfThereIsNoMoreAlbumsToRequest() {
        facebookApiManager.accessToken = "ClownKey"
        let testData = ["data": [
            ["id": "1", "name": "Thursday Clowning", "count": 1, "images": [["source": testUrlString, "width": 700, "height": 500]], "cover_photo": ["id": "cover_1"]],
            ]]
        facebookApiManager.result = testData

        var called: Bool = false
        facebookAlbumManager.loadNextBatchOfAlbums { _ in called = true }
        
        XCTAssertFalse(called)
    }
    
    func testLoadNextBatchOfAlbums_shouldPerformRequestWithProvidedNextUrl() {
        facebookApiManager.accessToken = "ClownKey"
        var testData: [String: Any] = [
            "paging": ["next": "clown1", "cursors": ["after" : "clown2"]],
            "data": [
            ["id": "1", "name": "Thursday Clowning", "count": 1, "images": [["source": testUrlString, "width": 700, "height": 500]], "cover_photo": ["id": "cover_1"]],
            ]]
 
        facebookApiManager.result = testData
        facebookAlbumManager.loadAlbums { _ in }
        XCTAssertTrue(facebookAlbumManager.hasMoreAlbumsToLoad)
        
        testData["paging"] = nil
        facebookApiManager.result = testData
        facebookAlbumManager.loadNextBatchOfAlbums { _ in }
        XCTAssertTrue(facebookApiManager.lastPath != nil && facebookApiManager.lastPath!.contains("clown2"))
        XCTAssertFalse(facebookAlbumManager.hasMoreAlbumsToLoad)
    }
}
