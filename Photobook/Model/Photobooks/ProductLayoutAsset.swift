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

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutAsset: Codable {
    
    var transform = CGAffineTransform.identity

    // Should be set to true before assigning a new container size if the layout has changed.
    var shouldFitAsset: Bool = false
    
    var containerSize: CGSize! {
        didSet {
            guard !shouldFitAsset && oldValue != nil else {
                fitAssetToContainer()
                return
            }

            let relativeWidth = containerSize.width / oldValue.width
            let relativeHeight = containerSize.height / oldValue.height

            transform = LayoutUtils.adjustTransform(transform, byFactorX: relativeWidth, factorY: relativeHeight)
            adjustTransform()
        }
    }
    
    var asset: Asset? {
        didSet {
            currentImage = nil
            currentIdentifier = nil
            fitAssetToContainer()
        }
    }

    /// Identifier for the asset linked to currentImage
    var currentIdentifier: String?
    
    /// Already loaded image resource
    var currentImage: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case transform, containerSize, asset
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transform, forKey: .transform)
        try container.encode(containerSize, forKey: .containerSize)

        var data: Data? = nil
        if let asset = asset as? PhotosAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? URLAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? ImageAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? PhotosAssetMock {
            data = try PropertyListEncoder().encode(asset)
        }
        try container.encode(data, forKey: .asset)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        containerSize = try values.decodeIfPresent(CGSize.self, forKey: .containerSize)

        if let data = try values.decodeIfPresent(Data.self, forKey: .asset) {
            if let loadedAsset = try? PropertyListDecoder().decode(URLAsset.self, from: data) {
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(ImageAsset.self, from: data) {
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(PhotosAsset.self, from: data) { // Keep the PhotosAsset case last because otherwise it triggers NSPhotoLibraryUsageDescription crash if not present, which might not be needed
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(PhotosAssetMock.self, from: data) {
                asset = loadedAsset
            }
        }
    }
    
    func adjustTransform() {
        guard let asset = asset, let containerSize = containerSize else { return }
        
        transform = LayoutUtils.adjustTransform(transform, forViewSize: asset.size, inContainerSize: containerSize)
    }
    
    func fitAssetToContainer() {
        guard let asset = asset, let containerSize = containerSize else { return }
        
        // Calculate scale. Ignore any previous translation or rotation
        let scale = LayoutUtils.scaleToFill(containerSize: containerSize, withSize: asset.size, atAngle: 0.0)
        transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
    }
    
    func shallowCopy() -> ProductLayoutAsset {
        let aLayoutAsset = ProductLayoutAsset()
        aLayoutAsset.asset = asset
        aLayoutAsset.containerSize = containerSize
        aLayoutAsset.transform = transform
        aLayoutAsset.currentImage = currentImage
        aLayoutAsset.currentIdentifier = currentIdentifier
        return aLayoutAsset
    }
}

