//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol OrderSummaryManagerDelegate: class {
    func orderSummaryManagerWillUpdate()
    func orderSummaryManagerDidSetPreviewImageUrl()
    func orderSummaryManagerFailedToSetPreviewImageUrl()
    func orderSummaryManagerDidUpdate(_ summary: OrderSummary?, error: ErrorMessage?)
    func orderSummaryManagerFailedToApply(_ upsell: UpsellOption, error: ErrorMessage)
}

class OrderSummaryManager {
    
    var coverPageSnapshotImage: UIImage? {
        didSet {
            product.coverSnapshot = coverPageSnapshotImage
            uploadCoverImage()
        }
    }
    var templates: [PhotobookTemplate]!
    var product: PhotobookProduct!
    lazy var apiManager = PhotobookAPIManager()
    lazy var apiClient = APIClient.shared
    weak var delegate: OrderSummaryManagerDelegate?
    
    // Layouts configured by previous UX
    private var layouts: [ProductLayout] {
        get {
            return product.productLayouts
        }
    }
    private var isUploadingCoverImage = false
    
    private(set) var upsellOptions: [UpsellOption]?
    private(set) var summary: OrderSummary?
    
    private(set) var selectedUpsellOptions = Set<UpsellOption>()
    
    func getSummary() {
        if upsellOptions?.isEmpty ?? true {
            fetchOrderSummary()
        } else {
            applyUpsells()
        }
    }
    
    func toggleUpsellOption(_ option: UpsellOption) {
        if isUpsellOptionSelected(option) {
            deselectUpsellOption(option)
        } else {
            selectUpsellOption(option)
        }
    }
    
    func selectUpsellOption(_ option: UpsellOption) {
        selectedUpsellOptions.insert(option)
        applyUpsells { [weak welf = self] (error) in
            welf?.selectedUpsellOptions.remove(option)
            welf?.delegate?.orderSummaryManagerFailedToApply(option, error: error)
        }
    }
    
    func deselectUpsellOption(_ option: UpsellOption) {
        selectedUpsellOptions.remove(option)
        applyUpsells { [weak welf = self] (error) in
            welf?.selectedUpsellOptions.insert(option)
            welf?.delegate?.orderSummaryManagerFailedToApply(option, error: error)
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
        delegate?.orderSummaryManagerWillUpdate()
        
        summary = nil
        
        apiManager.getOrderSummary(product: product) { [weak self] (summary, upsellOptions, productPayload, error) in
            
            guard let stelf = self else { return }
            guard let summary = summary else {
                if let error = error as? APIClientError, case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                let errorMessage = ErrorMessage(error != nil ? error! : APIClientError.generic)
                
                stelf.delegate?.orderSummaryManagerDidUpdate(nil, error: errorMessage)
                return
            }
            
            stelf.product.setUpsellData(template: stelf.product.photobookTemplate, payload: productPayload)
            stelf.upsellOptions = upsellOptions
            stelf.handleReceivingSummary(summary)
        }
    }
    
    private func applyUpsells(_ failure:((_ error: ErrorMessage) -> Void)? = nil) {
        delegate?.orderSummaryManagerWillUpdate()
        
        apiManager.applyUpsells(product: product, upsellOptions: Array<UpsellOption>(selectedUpsellOptions)) { [weak welf = self] (summary, upsoldTemplateId, productPayload, error) in
            
            // API errors
            guard let summary = summary, let templateId = upsoldTemplateId else {
                if let error = error as? APIClientError, case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                let errorMessage = ErrorMessage(error != nil ? error! : APIClientError.generic)
                
                failure?(errorMessage)
                return
            }

            // Check if the template ID can be matched
            guard let upsoldTemplate = welf?.templates?.first(where: {$0.templateId == templateId}) else {
                Analytics.shared.trackError(.upsellError, "ApplyUpsells: Failed to find \(templateId)")
                
                failure?(ErrorMessage(.generic))
                return
            }
            
            welf?.product.setUpsellData(template: upsoldTemplate, payload: productPayload)
            welf?.handleReceivingSummary(summary)
        }
    }
    
    private func handleReceivingSummary(_ summary: OrderSummary) {
        self.summary = summary
        delegate?.orderSummaryManagerDidUpdate(summary, error: nil)
        if isPreviewImageUrlReady() {
            delegate?.orderSummaryManagerDidSetPreviewImageUrl()
        }
    }
    
    func fetchPreviewImage(withSize size: CGSize, completion: @escaping (UIImage?) -> Void) {
        
        guard let coverImageUrl = product.pigCoverUrl else {
            completion(nil)
            return
        }
        
        if let summary = summary, let url = Pig.previewImageUrl(withBaseUrlString: summary.pigBaseUrl, coverUrlString: coverImageUrl, size: size) {
            Pig.fetchPreviewImage(with: url, completion: completion)
        } else {
            completion(nil)
        }
    }
    
    private func uploadCoverImage() {
        
        guard let coverImage = coverPageSnapshotImage else {
            delegate?.orderSummaryManagerFailedToSetPreviewImageUrl()
            return
        }
        
        isUploadingCoverImage = true
        Pig.uploadImage(coverImage) { [weak welf = self] url, error in
            welf?.isUploadingCoverImage = false
            
            if error != nil {
                welf?.delegate?.orderSummaryManagerFailedToSetPreviewImageUrl()
                return
            }

            welf?.product.pigCoverUrl = url
            if welf?.isPreviewImageUrlReady() ?? false {
                welf?.delegate?.orderSummaryManagerDidSetPreviewImageUrl()
            }
        }
    }
    
    private func isPreviewImageUrlReady() -> Bool {
        return product.pigCoverUrl != nil && summary != nil
    }
}
