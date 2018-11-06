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

import UIKit
import Photos

// Photos asset subclass with stubs to be used in testing
class PhotosAssetMock: PhotosAsset {
    private var stubSize = CGSize(width: 3000.0, height: 2000.0)
    var height: CGFloat = 2000.0
    
    var identifierStub: String! = "PhotosAssetID"
    
    override var identifier: String! {
        get { return identifierStub }
        set {}
    }
    override var size: CGSize { return stubSize }
    
    var imageStub: UIImage?
    var imageDataStub: Data?
    var imageExtension: AssetDataFileExtension = .jpg
    var error: Error?
    
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
    
    override func image(size: CGSize, loadThumbnailFirst: Bool = false, progressHandler: ((Int64, Int64) -> Void)? = nil, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        if imageStub != nil || error != nil {
            completionHandler(imageStub, error)
            return
        }
        super.image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    override func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        if imageDataStub != nil || error != nil {
            completionHandler(imageDataStub, imageExtension, error)
            return
        }
        super.imageData(progressHandler: progressHandler, completionHandler: completionHandler)
    }
}

extension PhotosAssetMock {
    @objc func value(forKey key: String) -> Any? {
        switch key {
        case "uploadUrl":
            return uploadUrl
        default:
            return nil
        }
    }
}
