//
//  ImageAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 26/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

/// Image resource based on a UIImage that can be used in a photo book
public class ImageAsset: NSObject, Asset {
    
    /// Image representation of the asset
    public var image: UIImage!
    
    /// Date associated with this asset
    public var date: Date? = nil
    
    var identifier = UUID().uuidString
    var albumIdentifier: String? = nil
    var uploadUrl: String?
    var size: CGSize {
        guard image != nil else { return .zero }
        return image.size
    }

    public convenience init(_ image: UIImage) {
        self.init()
        self.image = image
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "identifier")
        if uploadUrl != nil {
            aCoder.encode(uploadUrl, forKey: "uploadUrl")
            return
        }
        
        let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
        aCoder.encode(imageData, forKey: "image")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?
            else { return nil }
        
        self.init()
        self.identifier = identifier
        
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        
        if let imageData = aDecoder.decodeObject(of: NSData.self, forKey: "image") as Data? {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as? UIImage
        }
    }

    func image(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        guard let image = image else {
            completionHandler(nil, nil)
            return
        }
        completionHandler(image, nil)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        guard let image = image else {
            completionHandler(nil, .unsupported, nil)
            return
        }
        let data = UIImageJPEGRepresentation(image, 0.8)
        completionHandler(data, .jpg, nil)
    }
}
