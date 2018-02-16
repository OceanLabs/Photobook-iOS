//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol OrderSummaryManagerDelegate : class {
    func orderSummaryManagerWillUpdate(_ manager:OrderSummaryManager)
    func orderSummaryManager(_ manager:OrderSummaryManager, didUpdatePreviewImage success:Bool)
    func orderSummaryManager(_ manager:OrderSummaryManager, didUpdateSummary success:Bool)
    func orderSummaryManagerSizeForPreviewImage(_ manager:OrderSummaryManager) -> CGSize
}

class OrderSummaryManager {
    
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
    private var selectedUpsellOptions:Set<UpsellOption> = []
    private(set) var summary:OrderSummary?
    private(set) var previewImage:UIImage?
    private(set) var upsoldProduct:Photobook? //product to place the order with. Reflects user's selected upsell options.
    
    weak var delegate:OrderSummaryManagerDelegate?
    
    init(withDelegate delegate:OrderSummaryManagerDelegate) {
        self.delegate = delegate
    }
    
    func refresh() {
        delegate?.orderSummaryManagerWillUpdate(self)
        
        summary = nil
        previewImage = nil
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
    
    func fetchProductDetails() {
        
        //TODO: mock data REMOVE
        let randomInt = arc4random_uniform(3)
        let filename = "order_summary_\(randomInt)"
        print("mock file: " + filename)
        
        guard let summaryDict = JSON.parse(file: filename) as? [String:Any] else {
            delegate?.orderSummaryManager(self, didUpdateSummary: false)
            return
        }
        
        //summary
        guard let summary = OrderSummary(summaryDict) else {
            delegate?.orderSummaryManager(self, didUpdateSummary: false)
            delegate?.orderSummaryManager(self, didUpdatePreviewImage: false) //no summary, no preview
            return
        }
        self.summary = summary
        self.delegate?.orderSummaryManager(self, didUpdateSummary: true)
        
        //preview image
        fetchPreviewImage()
        
    }
    
    private func fetchPreviewImage() {
        
        guard let coverImageUrl = coverImageUrl else {
            return
        }
        
        let size = delegate?.orderSummaryManagerSizeForPreviewImage(self) ?? CGSize.zero
        
        if let summary = summary,
            let imageUrl = summary.previewImageUrl(withCoverImageUrl: coverImageUrl, size: size) {
            APIClient.shared.get(context: .none, endpoint: imageUrl.absoluteString, parameters: nil, completion: { (data, error) in
                self.previewImage = data as? UIImage
                DispatchQueue.main.async { self.delegate?.orderSummaryManager(self, didUpdatePreviewImage: self.previewImage != nil) }
            })
        } else {
            DispatchQueue.main.async { self.delegate?.orderSummaryManager(self, didUpdatePreviewImage: false) }
        }
    }
    
    private func uploadCoverImage() {
        isUploadingCoverImage = true
        
        guard layouts.count > 0, let asset = layouts[0].asset else {
            self.isUploadingCoverImage = false
            DispatchQueue.main.async { self.delegate?.orderSummaryManager(self, didUpdatePreviewImage: false) }
            return
        }
        
        let imageSize = CGSize(width:300, height:300)
        asset.image(size: imageSize, loadThumbnailsFirst: false, progressHandler: nil, completionHandler: { (image, error) in
            if let image = image {
                
                APIClient.shared.uploadImage(image, imageName: "OrderSummaryPreviewImage.jpeg", context: .pig, endpoint: "upload/", completion: { (json, error) in
                    self.isUploadingCoverImage = false
                    
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    guard let dictionary = json as? [String:AnyObject], let url = dictionary["full"] as? String else {
                        print("OrderSummaryManager: Couldn't parse URL of uploaded image")
                        DispatchQueue.main.async { self.delegate?.orderSummaryManager(self, didUpdatePreviewImage: false) }
                        return
                    }
                    
                    self.coverImageUrl = url
                    self.fetchPreviewImage()
                })
            } else {
                print("OrderSummaryManager: Couldn't get image for asset")
                self.isUploadingCoverImage = false
                DispatchQueue.main.async { self.delegate?.orderSummaryManager(self, didUpdatePreviewImage: false) }
            }
        })
    }
}
