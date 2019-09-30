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
        
        apiManager.getOrderSummary(product: product) { [weak welf = self] result in
            guard let stelf = welf else { return }
            
            if case .failure(let error) = result {
                if case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                stelf.delegate?.orderSummaryManagerDidUpdate(nil, error: ErrorMessage(error))
                return
            }
            let summaryInfo = try! result.get()
            
            stelf.product.setUpsellData(template: stelf.product.photobookTemplate, payload: summaryInfo.productPayload)
            stelf.upsellOptions = summaryInfo.upsellOptions
            stelf.handleReceivingSummary(summaryInfo.orderSummary)
        }
    }
    
    private func applyUpsells(_ failure:((_ error: ErrorMessage) -> Void)? = nil) {
        delegate?.orderSummaryManagerWillUpdate()
        
        apiManager.applyUpsells(product: product, upsellOptions: Array<UpsellOption>(selectedUpsellOptions)) { [weak welf = self] result in
            guard let stelf = welf else { return }
            if case .failure(let error) = result {
                if case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                failure?(ErrorMessage(error))
                return
            }
            let upsellInfo = try! result.get()

            // Check if the template ID can be matched
            guard let upsoldTemplate = stelf.templates?.first(where: {$0.templateId == upsellInfo.upsoldTemplateId}) else {
                Analytics.shared.trackError(.upsellError, "ApplyUpsells: Failed to find \(upsellInfo.upsoldTemplateId)")
                
                failure?(ErrorMessage(.generic))
                return
            }

            stelf.product.setUpsellData(template: upsoldTemplate, payload: upsellInfo.productPayload)
            stelf.handleReceivingSummary(upsellInfo.summary)
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
        Pig.uploadImage(coverImage) { [weak welf = self] result in
            guard let stelf = welf else { return }
            
            stelf.isUploadingCoverImage = false
            switch result {
            case .success(let url):
                stelf.product.pigCoverUrl = url
                if stelf.isPreviewImageUrlReady() {
                    stelf.delegate?.orderSummaryManagerDidSetPreviewImageUrl()
                    return
                }
                fallthrough
            case .failure:
                stelf.delegate?.orderSummaryManagerFailedToSetPreviewImageUrl()
            }
        }
    }
    
    private func isPreviewImageUrlReady() -> Bool {
        return product.pigCoverUrl != nil && summary != nil
    }
}
