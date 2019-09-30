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
@testable import Photobook_App
@testable import Photobook

class StoriesManagerTests: XCTestCase {
    
    // Creates a fake story - moment - photo structure
    private func photoLibrarySetup() -> ([PHCollectionListMock], [PHAssetCollectionMock], [PHAssetMock]) {
        var collectionLists = [PHCollectionListMock]()
        var assetCollections = [PHAssetCollectionMock]()
        var assets = [PHAssetMock]()
        
        for i in 0 ..< 5 {
            let collectionList = PHCollectionListMock()
            collectionList.localIdentifierStub = "list_id\(i)"
            collectionList.localizedTitleStub = "list_title\(i)"
            collectionList.startDateStub = Date()
            collectionList.endDateStub = Date()
            collectionLists.append(collectionList)
            
            for j in 0 ..< 5 {
                let assetCollection = PHAssetCollectionMock()
                assetCollection.localIdentifierStub = "collection_id_\(i)_\(j)"
                assetCollection.listIdentifier = collectionList.localIdentifier
                assetCollections.append(assetCollection)
                
                for k in 0 ..< 4 {
                    let asset = PHAssetMock()
                    asset.localIdentifierStub = "asset_id_\(i)_\(j)_\(k)"
                    asset.listIdentifier = assetCollection.localIdentifier
                    asset.widthStub = 3000
                    asset.heightStub = 2000
                    assets.append(asset)
                }
            }
        }
        
        return (collectionLists, assetCollections, assets)
    }
    
    private func managerWithSetup(collectionLists: [PHCollectionListMock], assetCollections: [PHAssetCollectionMock], assets: [PHAssetMock]) -> StoriesManager {
        
        let storiesManager = StoriesManager()
        
        let collectionListManager = CollectionListManagerMock()
        collectionListManager.phCollectionListStub = collectionLists
        storiesManager.collectionListManager = collectionListManager
        
        let collectionManager = CollectionManagerMock()
        collectionManager.phAssetCollectionStub = assetCollections
        storiesManager.collectionManager = collectionManager
        
        let assetManager = AssetManagerMock()
        assetManager.phAssetsStub = assets
        storiesManager.assetManager = assetManager

        return storiesManager
    }
        
    func testLoadTopStories_storiesShouldBeEmptyIfThereAreNoMomentsLists() {
        let (_, assetCollections, assets) = photoLibrarySetup()
        
        let storiesManager = managerWithSetup(collectionLists: [PHCollectionListMock](), assetCollections: assetCollections, assets: assets)

        let expectation = XCTestExpectation(description: "Should be empty")
        storiesManager.loadTopStories() {
            guard storiesManager.stories.count == 0 else { return }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadTopStories_shouldNotLoadOldStories() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        for i in 0 ..< collectionLists.count {
            collectionLists[i].startDateStub = Calendar.current.date(byAdding: .year, value: -i, to: Date())
        }
        
        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)
        
        let expectation = XCTestExpectation(description: "Should have 3 stories")
        storiesManager.loadTopStories() {
            guard storiesManager.stories.count == 3 else { return }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadStopStories_shouldOnlyAddStoriesWithAMinNumberOfAssets() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        // Change list id on last asset, reducing count to 19
        assets[assets.count - 1].listIdentifier = "another_id"

        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)
        
        let expectation = XCTestExpectation(description: "Should have 4 stories")
        storiesManager.loadTopStories() {
            guard storiesManager.stories.count == 4 else { return }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadTopStories_shouldBreakDownTheLocationsInTheTitle() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        collectionLists[0].localizedTitleStub = "Barcelona & Madrid"
        collectionLists[1].localizedTitleStub = "Segovia, Seville & Grenada"
        collectionLists[2].localizedTitleStub = "London - Regent's Park"
        collectionLists[3].localizedTitleStub = "Donostia-San Sebastián"
        collectionLists[4].localizedTitleStub = "Munich"

        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)
        
        let expectation = XCTestExpectation(description: "Should breakdown the titles")
        storiesManager.loadTopStories() {
            let stories = storiesManager.stories
            guard stories.count == 5 else { return }
            
            // Assumes the loading is in a descending order by date
            XCTAssertEqual(stories[0].components, ["Munich"])
            XCTAssertEqual(stories[1].components, ["Donostia-San Sebastián"])
            XCTAssertEqual(stories[2].components, ["London"])
            XCTAssertEqual(stories[3].components, ["Segovia", "Seville", "Grenada"])
            XCTAssertEqual(stories[4].components, ["Barcelona", "Madrid"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }    
}
