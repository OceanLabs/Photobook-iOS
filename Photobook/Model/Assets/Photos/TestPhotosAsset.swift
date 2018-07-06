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
    
    override var identifier: String! {
        get { return identifierStub }
        set {}
    }
    override var size: CGSize { return stubSize }
    
    init(_ asset: PHAsset = PHAsset(), size: CGSize? = nil) {
        super.init(asset, albumIdentifier: "album")
        if let size = size {
            stubSize = size
        }
    }

    enum CodingKeys: String, CodingKey {
        case identifierStub, stubSize
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifierStub, forKey: .identifierStub)
        try container.encode(stubSize, forKey: .stubSize)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifierStub = try values.decode(String.self, forKey: .identifierStub)
        stubSize = try values.decode(CGSize.self, forKey: .stubSize)
    }

//    required init?(coder aDecoder: NSCoder) {
//        super.init(PHAsset(), albumIdentifier: "")
//    }
//
//    required init(from decoder: Decoder) throws {
//        try super.init(from: decoder)
//    }
}
