//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

protocol OrderSummaryManagerDelegate: class {
    func orderSummaryManagerWillUpdate(_ manager: OrderSummaryManager)
    func orderSummaryManagerPreviewImageFinished(_ manager: OrderSummaryManager, success: Bool)
    func orderSummaryManager(_ manager: OrderSummaryManager, didUpdateSummary summary: OrderSummary)
    func orderSummaryManager(_ manager: OrderSummaryManager, updateSummaryFailedWithError error: Error?)
    func orderSummaryManager(_ manager: OrderSummaryManager, failedToApplyUpsell upsell: UpsellOption, error:Error?)
}

class OrderSummaryManager {
    
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
    
    var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    private(set) var selectedUpsellOptions = Set<UpsellOption>()
    
    weak var delegate: OrderSummaryManagerDelegate?
    
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
        applyUpsells { [weak self] (error) in
            if let strongSelf = self {
                strongSelf.selectedUpsellOptions.remove(option)
                strongSelf.delegate?.orderSummaryManager(strongSelf, failedToApplyUpsell: option, error: error)
            }
        }
    }
    
    func deselectUpsellOption(_ option:UpsellOption) {
        selectedUpsellOptions.remove(option)
        applyUpsells { [weak self] (error) in
            if let strongSelf = self {
                strongSelf.selectedUpsellOptions.insert(option)
                strongSelf.delegate?.orderSummaryManager(strongSelf, failedToApplyUpsell: option, error: error)
            }
        }
    }
    
    func applyUpsells(_ failure:((_ error: Error?) -> Void)? = nil) {
        delegate?.orderSummaryManagerWillUpdate(self)
        
        ProductManager.shared.applyUpsells(Array<UpsellOption>(selectedUpsellOptions)) { [weak self] (summary, error) in
            guard let summary = summary, error == nil else {
                failure?(error)
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
        self.delegate?.orderSummaryManagerWillUpdate(self)
        
        summary = nil
        previewImageUrl = nil
        
        if coverImageUrl == nil {
            uploadCoverImage()
        }
        
        apiManager.getOrderSummary(product: product) { [weak self] (summary, upsellOptions, productPayload, error) in
            
            if let strongSelf = self {
                guard let summary = summary else {
                    strongSelf.delegate?.orderSummaryManager(strongSelf, updateSummaryFailedWithError: error)
                    return
                }
                
                ProductManager.shared.upsoldPayload = productPayload
                strongSelf.upsellOptions = upsellOptions
                strongSelf.handleReceivingSummary(summary)
            }
        }
    }
    
    private func handleReceivingSummary(_ summary: OrderSummary) {
        self.summary = summary
        delegate?.orderSummaryManager(self, didUpdateSummary: summary)
        if coverImageUrl != nil {
            delegate?.orderSummaryManagerPreviewImageFinished(self, success: true)
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
            isUploadingCoverImage = false
            delegate?.orderSummaryManagerPreviewImageFinished(self, success: false)
            return
        }
        
        APIClient.shared.uploadImage(coverImage, imageName: "OrderSummaryPreviewImage.png", context: .pig, endpoint: "upload/", completion: { [weak self] (json, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.isUploadingCoverImage = false
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let dictionary = json as? [String:AnyObject], let url = dictionary["full"] as? String else {
                print("OrderSummaryManager: Couldn't parse URL of uploaded image")
                strongSelf.delegate?.orderSummaryManagerPreviewImageFinished(strongSelf, success: false)
                return
            }
            
            strongSelf.coverImageUrl = url
            if strongSelf.summary != nil {
                strongSelf.delegate?.orderSummaryManagerPreviewImageFinished(strongSelf, success: true)
            }
        })
    }
}
