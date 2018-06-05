//
//  TestPhotosAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 01/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

// Photos asset subclass with stubs to be used in testing
class TestPhotosAsset: PhotosAsset {
    private var stubSize = CGSize(width: 3000.0, height: 2000.0)
    var height: CGFloat = 2000.0
    
    var identifierStub: String! = "PhotosAssetID"
    
    override var size: CGSize { return stubSize }
    init(_ asset: PHAsset = PHAsset(), size: CGSize? = nil) {
        super.init(asset, albumIdentifier: "album")
        if let size = size {
            stubSize = size
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(PHAsset(), albumIdentifier: "")
    }
    
    override var identifier: String! {
        get { return identifierStub }
        set {}
    }
}
