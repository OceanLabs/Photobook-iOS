//
//  ImageAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 26/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

class ImageAsset: Asset {
    var image: UIImage!
    
    var identifier = UUID().uuidString
    var date: Date? = nil
    var albumIdentifier: String? = nil
    var size: CGSize {
        return image.size
    }
    var isLandscape: Bool {
        return size.width > size.height
    }
    var uploadUrl: String?
    
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
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "identifier")
        if uploadUrl != nil {
            aCoder.encode(uploadUrl, forKey: "uploadUrl")
            return
        }
        
        let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
        aCoder.encode(imageData, forKey: "image")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?
            else { return nil }
        
        self.init()
        self.identifier = identifier
        
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        
        if let imageData = aDecoder.decodeObject(of: NSData.self, forKey: "image") as Data? {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as? UIImage
        }
    }
}
