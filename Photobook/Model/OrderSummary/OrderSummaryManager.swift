//
//  OrderManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol OrderSummaryManagerDelegate : class {
    func orderSummaryManager(_ manager:OrderSummaryManager, didUpdate success:Bool)
}

class OrderSummaryManager {
    
    private let taskReferenceImagePreview = "OrderSummaryManager-ProductPreviewImage"
    
    //layouts configured by previous UX
    private var layouts:[ProductLayout] {
        get {
            return ProductManager.shared.productLayouts
        }
    }
    private var coverImageUrl:String?
    
    //original product provided by previous UX
    var product:Photobook? {
        get {
            return ProductManager.shared.product
        }
    }
    var upsellOptions:[UpsellOption]? {
        get {
            return ProductManager.shared.upsellOptions
        }
    }
    private var selectedUpsellOptions:Set<UpsellOption> = []
    private(set) var summary:OrderSummary?
    private(set) var previewImage:UIImage?
    private(set) var upsoldProduct:Photobook? //product to place the order with. Reflects user's selected upsell options.
    
    weak var delegate:OrderSummaryManagerDelegate?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(imageUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
        
        refresh(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refresh(_ resetImage:Bool = false) {
        
        if coverImageUrl != nil && resetImage == false {
            fetchProductDetails()
        } else {
            uploadPreviewImage()
        }
    }
    
    func selectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.insert(option)
        refresh(false)
    }
    
    func deselectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.remove(option)
        refresh(false)
    }
    
    func isUpsellOptionSelected(_ option:UpsellOption) -> Bool {
        return selectedUpsellOptions.contains(option)
    }
    
    func fetchProductDetails() {
        
        //TODO: mock data REMOVE
        let randomInt = arc4random_uniform(4)
        let filename = "order_summary_\(randomInt)"
        print("mock file: " + filename)
        
        guard let summaryDict = JSON.parse(file: filename) as? [String:Any] else {
            delegate?.orderSummaryManager(self, didUpdate: false)
            return
        }
        
        //summary
        guard let summary = OrderSummary(summaryDict), let coverImageUrl = coverImageUrl else {
            delegate?.orderSummaryManager(self, didUpdate: false)
            return
        }
        self.summary = summary
        
        if let imageUrl = summary.previewImageUrl(withCoverImageUrl: coverImageUrl, size: CGSize(width: 300, height: 300)) {
            URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, response, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let data = data {
                        self.previewImage = UIImage(data: data)
                    }
                    self.delegate?.orderSummaryManager(self, didUpdate: true)
                })
                
            }).resume()
        }
        
    }
    
    private func uploadPreviewImage() {
        
        guard layouts.count > 0, let asset = layouts[0].asset else {
            self.fetchProductDetails()
            return
        }
        
        asset.image(size: assetMaximumSize, applyEdits: false, progressHandler: nil, completionHandler: { (image, error) in
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
        
        defer {
            fetchProductDetails() //always proceed to fetch product details that'll also take care of sending notifications to all observers
        }
        
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
    }
}
