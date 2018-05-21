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
    static let notificationConnectionError = Notification.Name("ly.kite.sdk.orderSummaryManager.connectionError")
    static let notificationApplyUpsellFailed = Notification.Name("ly.kite.sdk.orderSummaryManager.applyUpsellFailed")
    
    private lazy var apiManager = PhotobookAPIManager()
    
    //layouts configured by previous UX
    private var layouts: [ProductLayout] {
        get {
            return product.productLayouts
        }
    }
    private var coverImageUrl:String?
    private var isUploadingCoverImage = false
    
    private(set) var upsellOptions: [UpsellOption]?
    private(set) var summary: OrderSummary?
    private var previewImageUrl: String?
    
    var coverPageSnapshotImage: UIImage?
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    private(set) var selectedUpsellOptions = Set<UpsellOption>()
    
    static let shared = OrderSummaryManager()
    
    func reset() {
        upsellOptions = nil
        selectedUpsellOptions.removeAll()
        
        previewImageUrl = nil
        coverImageUrl = nil
        isUploadingCoverImage = false
    }
    
    func refresh() {
        if upsellOptions?.isEmpty ?? true {
            fetchOrderSummary()
        } else {
            applyUpsells()
        }
    }
    
    func toggleUpsellOption(_ option:UpsellOption) {
        if isUpsellOptionSelected(option) {
            deselectUpsellOption(option)
        } else {
            selectUpsellOption(option)
        }
    }
    
    func selectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.insert(option)
        applyUpsells { [weak self] in
            self?.selectedUpsellOptions.remove(option)
        }
    }
    
    func deselectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.remove(option)
        applyUpsells { [weak self] in
            self?.selectedUpsellOptions.insert(option)
        }
    }
    
    func applyUpsells(_ failure:(() -> Void)? = nil) {
        NotificationCenter.default.post(name: OrderSummaryManager.notificationWillUpdate, object: self)
        
        ProductManager.shared.applyUpsells(Array<UpsellOption>(selectedUpsellOptions)) { [weak self] (summary, error) in
            if error != nil {
                failure?()
                NotificationCenter.default.post(name: OrderSummaryManager.notificationApplyUpsellFailed, object: self)
                return
            }
            self?.handleReceivingSummary(summary)
        }
    }
    
    func isUpsellOptionSelected(_ option:UpsellOption) -> Bool {
        return selectedUpsellOptions.contains(option)
    }
}

// MARK - API Requests
extension OrderSummaryManager {
    
    /// Initial summary fetch
    private func fetchOrderSummary() {
        NotificationCenter.default.post(name: OrderSummaryManager.notificationWillUpdate, object: self)
        
        summary = nil
        previewImageUrl = nil
        
        if coverImageUrl == nil {
            uploadCoverImage()
        }
        
        apiManager.getOrderSummary(product: product) { [weak self] (summary, upsellOptions, productPayload, error) in
            
            if let error = error as? APIClientError, case APIClientError.connection = error {
                NotificationCenter.default.post(name: OrderSummaryManager.notificationConnectionError, object: self)
                return
            }
            
            self?.product.payload = productPayload
            ProductManager.shared.upsoldProduct = self?.product
            self?.upsellOptions = upsellOptions
            self?.handleReceivingSummary(summary)
        }
    }
    
    private func handleReceivingSummary(_ summary: OrderSummary?) {
        self.summary = summary
        NotificationCenter.default.post(name: OrderSummaryManager.notificationDidUpdateSummary, object: self)
        if self.coverImageUrl != nil {
            NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageReady, object: self)
        }
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
    
    private func uploadCoverImage() {
        isUploadingCoverImage = true
        
        guard let coverImage = coverPageSnapshotImage else {
            self.isUploadingCoverImage = false
            NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageFailed, object: self)
            return
        }
        
        APIClient.shared.uploadImage(coverImage, imageName: "OrderSummaryPreviewImage.png", context: .pig, endpoint: "upload/", completion: { [weak self] (json, error) in
            self?.isUploadingCoverImage = false
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let dictionary = json as? [String:AnyObject], let url = dictionary["full"] as? String else {
                print("OrderSummaryManager: Couldn't parse URL of uploaded image")
                NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageFailed, object: self)
                return
            }
            
            self?.coverImageUrl = url
            if self?.summary != nil {
                NotificationCenter.default.post(name: OrderSummaryManager.notificationPreviewImageReady, object: self)
            }
        })
    }
}
