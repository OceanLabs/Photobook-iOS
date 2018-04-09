//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

class OrderSummaryManager {
    static let notificationWillUpdate = Notification.Name("ly.kite.sdk.orderSummaryManager.willUpdate")
    static let notificationPreviewImageReady = Notification.Name("ly.kite.sdk.orderSummaryManager.previewImageReady")
    static let notificationPreviewImageFailed = Notification.Name("ly.kite.sdk.orderSummaryManager.previewImageFailed")
    static let notificationDidUpdateSummary = Notification.Name("ly.kite.sdk.orderSummaryManager.didUpdateSummary")
    
    //layouts configured by previous UX
    private var layouts:[ProductLayout] {
        get {
            return ProductManager.shared.productLayouts
        }
    }
    private var coverImageUrl:String?
    private var isUploadingCoverImage = false
    
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
    var selectedUpsellOptions:Set<UpsellOption> = []
    private(set) var summary:OrderSummary?
    private(set) var upsoldProduct:Photobook? //product to place the order with. Reflects user's selected upsell options.
    private var previewImageUrl:String?
    
    var coverPageSnapshotImage:UIImage?
    
    static let shared = OrderSummaryManager()
    
    func refresh() {
        NotificationCenter.default.post(name: OrderSummaryManager.notificationWillUpdate, object: self)
        
        summary = nil
        previewImageUrl = nil
        upsoldProduct = nil
        
        if coverImageUrl == nil {
            uploadCoverImage()
        }
        
        fetchProductDetails()
    }
    
    func selectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.insert(option)
        refresh()
    }
    
    func deselectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.remove(option)
        refresh()
    }
    
    func isUpsellOptionSelected(_ option:UpsellOption) -> Bool {
        return selectedUpsellOptions.contains(option)
    }
    
    func fetchPreviewImage(withSize size:CGSize, completion:@escaping (UIImage?) -> Void) {
        
        guard let coverImageUrl = coverImageUrl else {
            completion(nil)
            return
        }
        
        if let summary = summary,
            let imageUrl = summary.previewImageUrl(withCoverImageUrl: coverImageUrl, size: size) {
            SDWebImageManager.shared().loadImage(with: imageUrl, options: [], progress: nil, completed: { image, _, error, _, _, _ in
                DispatchQueue.main.async {
                    completion(image)
                }
            })
        } else {
            completion(nil)
        }
    }
    
    private func fetchProductDetails() {
        
        //TODO: mock data REMOVE
        let randomInt = arc4random_uniform(3)
        let filename = "order_summary_\(randomInt)"
        print("mock file: " + filename)
        
        guard let summaryDict = JSON.parse(file: filename) as? [String:Any] else {
            NotificationCenter.default.post(name: OrderSummaryManager.notificationDidUpdateSummary, object: self)
            return
        }
        
        //summary
        guard let summary = OrderSummary(summaryDict) else {
            NotificationCenter.default.post(name: OrderSummaryManager.notificationDidUpdateSummary, object: self)
            return
        }
        self.summary = summary
        NotificationCenter.default.post(name: OrderSummaryManager.notificationDidUpdateSummary, object: self)
        if coverImageUrl != nil {
            NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageReady, object: self)
        }
    }
    
    private func uploadCoverImage() {
        isUploadingCoverImage = true
        
        guard let coverImage = coverPageSnapshotImage else {
            self.isUploadingCoverImage = false
            NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageFailed, object: self)
            return
        }
        
        APIClient.shared.uploadImage(coverImage, imageName: "OrderSummaryPreviewImage.png", context: .pig, endpoint: "upload/", completion: { (json, error) in
            self.isUploadingCoverImage = false
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let dictionary = json as? [String:AnyObject], let url = dictionary["full"] as? String else {
                print("OrderSummaryManager: Couldn't parse URL of uploaded image")
                NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageFailed, object: self)
                return
            }
            
            self.coverImageUrl = url
            if self.summary != nil {
                NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageReady, object: self)
            }
        })
    }
}
