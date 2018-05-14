//
//  ImageAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 26/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

/// Image resource based on a UIImage that can be used in a photo book
@objc public class ImageAsset: NSObject, NSCoding, Asset {
    
    /// Image representation of the asset
    @objc internal(set) public var image: UIImage
    
    /// Date associated with this asset
    @objc internal(set) public var date: Date? = nil
    
    var identifier = UUID().uuidString
    var albumIdentifier: String? = nil
    var uploadUrl: String?
    var size: CGSize { return image.size }

    /// Init
    ///
    /// - Parameters:
    ///   - image: Image representation of the asset
    ///   - date: Associated date
    @objc public init(image: UIImage, date: Date? = nil) {
        self.image = image
        self.date = date
    }
    
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "identifier")
        if uploadUrl != nil {
            aCoder.encode(uploadUrl, forKey: "uploadUrl")
            return
        }
        
        let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
        aCoder.encode(imageData, forKey: "image")
        aCoder.encode(date, forKey: "date")
    }
    
    @objc public required convenience init?(coder aDecoder: NSCoder) {
        guard let imageData = aDecoder.decodeObject(of: NSData.self, forKey: "image") as Data?,
              let image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as? UIImage else {
            return nil
        }
        
        self.init(image: image)
        self.identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier")! as String
        self.date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        
    }

    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        completionHandler(image, nil)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        let data = UIImageJPEGRepresentation(image, 0.8)
        completionHandler(data, .jpg, nil)
    }
}
