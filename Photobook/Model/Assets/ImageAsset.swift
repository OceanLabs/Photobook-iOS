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

/// Image resource based on a UIImage that can be used in a photo book
class ImageAsset: Asset {
    
    /// Image representation of the asset
    var image: UIImage?
    
    /// Date associated with this asset
    var date: Date? = nil
    
    var identifier: String! = UUID().uuidString
    var albumIdentifier: String? = nil
    var uploadUrl: String?
    var size: CGSize { return image?.size ?? .zero }

    /// Init
    ///
    /// - Parameters:
    ///   - image: Image representation of the asset
    ///   - date: Associated date
    init(image: UIImage, date: Date? = nil) {
        self.image = image
        self.date = date
    }
    
    enum CodingKeys: String, CodingKey {
        case imageIdentifier, albumIdentifier, image, date, uploadUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .imageIdentifier)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        
        if uploadUrl == nil, let image = image {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try values.decode(String.self, forKey: .imageIdentifier)
        if let imageData = try values.decodeIfPresent(Data.self, forKey: .image) {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as! UIImage?
        }
        
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
    }

    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        completionHandler(image, nil)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        // Edge case when the asset has been saved and a URL already exists. This method should not be needed in that situation.
        guard let image = image else {
            completionHandler(nil, .jpg, nil)
            return
        }
        let data = image.jpegData(compressionQuality: 0.8)
        completionHandler(data, .jpg, nil)
    }
}
