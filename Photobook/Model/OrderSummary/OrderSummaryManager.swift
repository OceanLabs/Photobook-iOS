//
//  OrderManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol OrderSummaryManagerDelegate : class {
    func orderSummaryManagerDidUpdate(_ manager:OrderSummaryManager)
    func orderSummaryManagerPreviewImageSize(_ manager:OrderSummaryManager) -> CGSize
}

class OrderSummaryManager {
    
    private let taskReferenceImagePreview = "OrderSummaryManager-ProductPreviewImage"
    
    //layouts configured by previous UX
    private var layouts:[ProductLayout] {
        get {
            return ProductManager.shared.productLayouts
        }
    }
    private var pigUrl:String? //doesn't include image parameters
    private var coverImageUrl:String?
    private var previewImageUrl:String? {
        get {
            guard let pigUrl = pigUrl, let coverImageUrl = coverImageUrl else {
                return nil
            }
            return getProductPreviewImage(pigUrl, coverImageUrl)
        }
    }
    
    //original product provided by previous UX
    public var product:Photobook? {
        get {
            return ProductManager.shared.product
        }
    }
    public var upsellOptions:[UpsellOption] {
        get {
            return getUpsellOptions() //TODO: replace with data from product object
        }
    }
    public var selectedUpsellOptions:Set<String> = []
    public private(set) var previewImage:UIImage?
    public private(set) var summary:[OrderSummaryItem] = []
    public private(set) var upsoldProduct:Photobook? //product to place the order with. Reflects user's selected upsell options.
    
    public weak var delegate:OrderSummaryManagerDelegate?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(imageUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
        
        refresh()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refresh() {
        if coverImageUrl != nil {
            fetchProductDetails()
        } else {
            uploadPreviewImage()
        }
    }
    
    func fetchProductDetails() {
        
        var priceDetails = [OrderSummaryItem]()
        
        // mock data
        guard let fileDict = json(file: "order_summary") as? [String:Any], let dictionaries = fileDict["summary"] as? [[String:Any]] else {
            return //return
        }
        
        //summary
        for dict in dictionaries {
            if let item = OrderSummaryItem(dict) {
                priceDetails.append(item)
            }
        }
        summary = priceDetails
        
        //image
        if let url = fileDict["imagePreviewUrl"] as? String {
            pigUrl = url
        }
        
        guard let previewImageUrl = previewImageUrl, let url = URL(string: previewImageUrl) else {
            self.previewImage = nil
            delegate?.orderSummaryManagerDidUpdate(self)
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.previewImage = UIImage(data: data!)
                self.delegate?.orderSummaryManagerDidUpdate(self)
            })
            
        }).resume()
    }
    
    private func uploadPreviewImage() {
        
        guard layouts.count > 0, let asset = layouts[0].asset else {
            return
        }
        
        asset.image(size: CGSize(width: Int.max, height: Int.max), applyEdits: false, progressHandler: nil, completionHandler: { (image, error) in
            if let image = image {
                APIClient.shared.uploadImage(image, imageName: self.taskReferenceImagePreview + ".jpeg", reference: self.taskReferenceImagePreview, context: .pig, endpoint: "upload/")
            } else {
                // fetch product details straight away
                print("OrderSummaryManager: Couldn't get image for asset")
                self.fetchProductDetails()
            }
        })
    }
    
    @objc func imageUploadFinished(_ notification: Notification) {
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            print("OrderSummaryManager: Task finished but could not cast user info")
            return
        }
        
        if let error = dictionary["error"] as? APIClientError {
            print(error.localizedDescription)
            return
        }
        
        guard let reference = dictionary["task_reference"] as? String, reference == taskReferenceImagePreview,
            let url = dictionary["full"] as? String else {
                return
        }
        
        coverImageUrl = url
        fetchProductDetails()
    }
    
    private func getProductPreviewImage(_ pigUrl:String, _ imageUrl:String) -> String {
        guard let delegate = delegate else {
            return ""
        }
        
        let size = delegate.orderSummaryManagerPreviewImageSize(self)
        
        let previewUrlString = pigUrl + "&image=" + imageUrl + "&size=\(size.width)x\(size.height)" + "&fill_mode=fit"
        return previewUrlString
    }
    
    private func json(file: String) -> AnyObject? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json") else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            return try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
        } catch {
            print("JSON: Could not parse file")
        }
        return nil
    }
    
    
    
    
    
    
    
    
    
    
    
    
    func getUpsellOptions() -> [UpsellOption] {
        let dictionaries = [
        [
            "type": "size",
            "displayName": "larger size (210x210)"
            ],
        [
            "type": "finish",
            "displayName": "gloss finish"
            ]
        ] as [[String: AnyObject]]
        
        var upsellOptions = [UpsellOption]()
        for dict in dictionaries {
            if let upsellOption = UpsellOption(dict) {
                upsellOptions.append(upsellOption)
            }
        }
        
        return upsellOptions
    }
    
    func getMockPhotobook() -> Photobook {
        let validDictionary = [
            "id": 10,
            "name": "210 x 210",
            "pageWidth": 1000,
            "pageHeight": 400,
            "coverWidth": 1030,
            "coverHeight": 415,
            "cost": [ "EUR": 10.00 as Decimal, "USD": 12.00 as Decimal, "GBP": 9.00 as Decimal ],
            "costPerPage": [ "EUR": 1.00 as Decimal, "USD": 1.20 as Decimal, "GBP": 0.85 as Decimal ],
            "coverLayouts": [ 9, 10 ],
            "layouts": [ 10, 11, 12, 13 ]
            ] as [String: AnyObject]
        
        return Photobook.parse(validDictionary)!
    }
}
