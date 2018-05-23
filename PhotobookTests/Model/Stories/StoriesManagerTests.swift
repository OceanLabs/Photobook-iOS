//
//  StoriesManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 08/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class StoriesManagerTests: XCTestCase {
    
    // Creates a fake story - moment - photo structure
    private func photoLibrarySetup() -> ([TestPHCollectionList], [TestPHAssetCollection], [TestPHAsset]) {
        var collectionLists = [TestPHCollectionList]()
        var assetCollections = [TestPHAssetCollection]()
        var assets = [TestPHAsset]()
        
        for i in 0 ..< 5 {
            let collectionList = TestPHCollectionList()
            collectionList.localIdentifierStub = "list_id\(i)"
            collectionList.localizedTitleStub = "list_title\(i)"
            collectionList.startDateStub = Date()
            collectionList.endDateStub = Date()
            collectionLists.append(collectionList)
            
            for j in 0 ..< 5 {
                let assetCollection = TestPHAssetCollection()
                assetCollection.localIdentifierStub = "collection_id_\(i)_\(j)"
                assetCollection.listIdentifier = collectionList.localIdentifier
                assetCollections.append(assetCollection)
                
                for k in 0 ..< 4 {
                    let asset = TestPHAsset()
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
    
    private func managerWithSetup(collectionLists: [TestPHCollectionList], assetCollections: [TestPHAssetCollection], assets: [TestPHAsset]) -> StoriesManager {
        
        let storiesManager = StoriesManager()
        
        let collectionListManager = TestCollectionListManager()
        collectionListManager.phCollectionListStub = collectionLists
        storiesManager.collectionListManager = collectionListManager
        
        let collectionManager = TestCollectionManager()
        collectionManager.phAssetCollectionStub = assetCollections
        storiesManager.collectionManager = collectionManager
        
        let assetManager = TestAssetManager()
        assetManager.phAssetsStub = assets
        storiesManager.assetManager = assetManager

        return storiesManager
    }
        
    func testLoadTopStories_storiesShouldBeEmptyIfThereAreNoMomentsLists() {
        let (_, assetCollections, assets) = photoLibrarySetup()
        
        let storiesManager = managerWithSetup(collectionLists: [TestPHCollectionList](), assetCollections: assetCollections, assets: assets)

        let expectation = XCTestExpectation(description: "Should be empty")
        storiesManager.loadTopStories() {
            guard storiesManager.stories.count == 0 else { return }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadTopStories_shouldNotLoadOldStories() {
        var (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
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
        var (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        // Change list id on last asset, reducing count to 19
        assets[assets.count - 1].listIdentifier = "another_id"

        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)

        storiesManager.productManager = ProductManager(apiManager: PhotobookAPIManager())
        
        let expectation = XCTestExpectation(description: "Should have 4 stories")
        storiesManager.loadTopStories() {
            guard storiesManager.stories.count == 4 else { return }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadTopStories_shouldBreakDownTheLocationsInTheTitle() {
        var (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
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
    
    func testPerformAutoSelectionIfNeeded_doesNothingIfAlreadyDone() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)

        let expectation = XCTestExpectation(description: "Should not select assets")
        storiesManager.loadTopStories() {
            guard let story = storiesManager.stories.first else { return }
            story.hasPerformedAutoSelection = true
            storiesManager.performAutoSelectionIfNeeded(on: story)
            self.XCTAssertEqualOptional(storiesManager.selectedAssetsManager(for: story)?.selectedAssets.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformAutoSelectionIfNeeded_shouldSelectAllAssets() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)

        storiesManager.productManager = ProductManager(apiManager: PhotobookAPIManager())
        
        let expectation = XCTestExpectation(description: "Should select all assets")
        storiesManager.loadTopStories() {
            guard let story = storiesManager.stories.first else { return }
            
            // Simulate the loading of physical assets
            var photoAssets = [TestPhotosAsset]()
            for i in 0 ..< story.photoCount {
                let photoAsset = TestPhotosAsset()
                photoAsset.identifierStub = "asset_id_0_0_\(i)"
                photoAssets.append(photoAsset)
            }
            story.assets = photoAssets

            storiesManager.performAutoSelectionIfNeeded(on: story)
            let selectedAssets = storiesManager.selectedAssetsManager(for: story)?.selectedAssets.count
            
            // Check that all 20 assets are selected
            self.XCTAssertEqualOptional(selectedAssets, story.photoCount)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformAutoSelectionIfNeeded_shouldSelectMinimumNumberOfAssets() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()

        // Add all assets to the first story
        for i in 0 ..< assets.count {
            assets[i].listIdentifier = "collection_id_0_0"
        }

        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)

        storiesManager.productManager = ProductManager(apiManager: PhotobookAPIManager())

        let expectation = XCTestExpectation(description: "Should select min assets")
        storiesManager.loadTopStories() {
            guard let story = storiesManager.stories.last else { return }

            // Simulate the loading of physical assets
            var photoAssets = [TestPhotosAsset]()
            for i in 0 ..< assets.count {
                let photoAsset = TestPhotosAsset()
                photoAsset.identifierStub = "asset_id_0_0_\(i)"
                photoAssets.append(photoAsset)
            }
            story.assets = photoAssets

            storiesManager.performAutoSelectionIfNeeded(on: story)
            let selectedAssets = storiesManager.selectedAssetsManager(for: story)?.selectedAssets.count

            // Check that min number of assets have been selected
            self.XCTAssertEqualOptional(selectedAssets, storiesManager.productManager.minimumRequiredPages)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // Test the case when selecting evenly from non-integer segments. E.g. 33 photos, 20 min assets = pick a photo from every 1.65 photos.
    func testPerformAutoSelectionIfNeeded_shouldSelectMinimumNumberOfAssetsWithFractionSegments() {
        let (collectionLists, assetCollections, assets) = photoLibrarySetup()
        
        let numberOfAssetsInStory = 33
        for i in 0 ..< numberOfAssetsInStory {
            assets[i].listIdentifier = assetCollections.first!.localIdentifier // Add all assets to the first list
        }
        
        let storiesManager = managerWithSetup(collectionLists: collectionLists, assetCollections: assetCollections, assets: assets)
        
        storiesManager.productManager = ProductManager(apiManager: PhotobookAPIManager())
        
        let expectation = XCTestExpectation(description: "Should select min assets")
        storiesManager.loadTopStories() {
            guard let story = storiesManager.stories.last else { return }
            
            // Simulate the loading of physical assets
            var photoAssets = [TestPhotosAsset]()
            for i in 0 ..< numberOfAssetsInStory {
                let photoAsset = TestPhotosAsset()
                photoAsset.identifierStub = "asset_id_0_0_\(i)"
                photoAssets.append(photoAsset)
            }
            story.assets = photoAssets
            
            storiesManager.performAutoSelectionIfNeeded(on: story)
            let selectedAssets = storiesManager.selectedAssetsManager(for: story)?.selectedAssets.count
            
            // Check that min number of assets have been selected
            self.XCTAssertEqualOptional(selectedAssets, storiesManager.productManager.minimumRequiredPages)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
