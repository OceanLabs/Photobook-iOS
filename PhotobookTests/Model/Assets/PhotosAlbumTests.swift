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
import Photos
@testable import Photobook

class PhotosAlbumTests: XCTestCase {
    
    let assetCollection = PHAssetCollectionMock()
    var photosAlbum: PhotosAlbum!
    
    var assets: [PHAssetMock]!
    
    override func setUp() {
        super.setUp()

        assets = [PHAssetMock]()
        for i in 0 ..< 10 {
            let asset = PHAssetMock()
            asset.localIdentifierStub = "local\(i)"
            asset.listIdentifier = assetCollection.localIdentifier
            assets.append(asset)
        }

        photosAlbum = PhotosAlbum(assetCollection)
        
        let assetManager = AssetManagerMock()
        assetManager.phAssetsStub = assets
        
        photosAlbum.assetManager = assetManager
    }
    
    func testInitialisation() {
        XCTAssertEqual(assetCollection.localIdentifier, photosAlbum.assetCollection.localIdentifier)
    }
    
    func testLoadAssetsFromPhotoLibrary() {
        photosAlbum.loadAssetsFromPhotoLibrary()
        
        // Check that identifiers match (same asset)
        for i in 0 ..< assets.count {
            XCTAssertEqualOptional(assets[i].localIdentifier, (photosAlbum.assets[i] as? PhotosAsset)?.photosAsset.localIdentifier)
        }
    }
    
    func testLoadAssets() {
        photosAlbum.loadAssets { (error) in
            // Check that identifiers match (same asset)
            
            for i in 0 ..< self.assets.count {
                self.XCTAssertEqualOptional(self.assets[i].localIdentifier, (self.photosAlbum.assets[i] as? PhotosAsset)?.photosAsset.localIdentifier)
            }
        }
    }
    
    func testChangedAssets() {
        let newAsset = PHAssetMock()
        newAsset.localIdentifierStub = "local11"
        newAsset.listIdentifier = assetCollection.localIdentifier
        
        photosAlbum.loadAssetsFromPhotoLibrary()
        
        let phChange = ChangeManagerMock()
        phChange.phInsertedAssetsStub = [ newAsset ]
        phChange.phRemovedAssetsStub = [ assets[0] ]
        
        let (inserted, removed) = photosAlbum.changedAssets(for: phChange)
        XCTAssertEqualOptional(inserted?.first?.identifier, newAsset.localIdentifier)
        XCTAssertEqualOptional(removed?.first?.identifier, assets[0].localIdentifier)
    }
}
