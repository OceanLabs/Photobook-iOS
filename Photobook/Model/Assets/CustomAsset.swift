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

@objc public protocol AssetDataSource: NSCoding {
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void)
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void)
}

class CustomAsset: Asset {
    var dataSource: AssetDataSource
    
    var identifier: String! = UUID().uuidString
    
    var albumIdentifier: String? = nil
    
    var size: CGSize
    
    var date: Date?
    
    var uploadUrl: String?
    
    init(dataSource: AssetDataSource, size: CGSize, date: Date? = nil) {
        self.dataSource = dataSource
        self.size = size
        self.date = date
    }
    
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        dataSource.image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        dataSource.imageData(progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    enum CodingKeys: String, CodingKey {
        case imageIdentifier, albumIdentifier, dataSource, size, date, uploadUrl
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try values.decode(String.self, forKey: .imageIdentifier)
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        size = try values.decode(CGSize.self, forKey: .size)
        
        let dataSourceData = try values.decode(Data.self, forKey: .dataSource)
        dataSource = NSKeyedUnarchiver.unarchiveObject(with: dataSourceData) as! AssetDataSource
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .imageIdentifier)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        try container.encode(size, forKey: .size)
        try container.encode(NSKeyedArchiver.archivedData(withRootObject: dataSource), forKey: .dataSource)
    }
}
