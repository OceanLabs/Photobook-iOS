//
//  SelectedAssetManagerTests.swift
//  PhotobookTests
//
//  Created by Julian Gruber on 18/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class SelectedAssetManagerTests: XCTestCase {
    
    let selectedAssetManager = SelectedAssetsManager()
    
    func addMockAssets() {
        let asset0 = PhotosAsset(PHAsset(), collection: PHAssetCollection())
        asset0.identifier = "id0"
        let asset1 = PhotosAsset(PHAsset(), collection: PHAssetCollection())
        asset1.identifier = "id1"
        selectedAssetManager.select([asset0, asset1])
        
        XCTAssert(selectedAssetManager.selectedAssets.count == 2)
    }
    
    override func setUp() {
        super.setUp()
        
        selectedAssetManager.deselectAllAssets()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSelectAsset() {
        addMockAssets()
    }
    
    func testDeselectAsset() {
        addMockAssets()
        
        
    }
    
    func testSelectAllAssetsForAlbum() {
        
    }
    
    func testDeselectAllAssetsForAlbum() {
        
    }
    
    func testDeselectAllAssets() {
        
        
        selectedAssetManager.deselectAllAssets()
        
        XCTAssert(selectedAssetManager.selectedAssets.count == 0)
    }
    
}
