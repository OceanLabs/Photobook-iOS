//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol OrderSummaryManagerDelegate : class {
    func orderSummaryManager(_ manager:OrderSummaryManager, didUpdate success:Bool)
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
        let randomInt = arc4random_uniform(3)
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
        
        let size = delegate?.orderSummaryManagerSizeForPreviewImage(self) ?? CGSize.zero
        
        if let imageUrl = summary.previewImageUrl(withCoverImageUrl: coverImageUrl, size: size) {
            APIClient.shared.get(context: .none, endpoint: imageUrl.absoluteString, parameters: nil, completion: { (data, error) in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.previewImage = data as? UIImage
                    self.delegate?.orderSummaryManager(self, didUpdate: true)
                })
            })
        }
        
    }
    
    private func uploadPreviewImage() {
        
        guard layouts.count > 0, let asset = layouts[0].asset else {
            self.fetchProductDetails()
            return
        }
        
        asset.image(size: assetMaximumSize, applyEdits: false, loadThumbnailsFirst: false, progressHandler: nil, completionHandler: { (image, error) in
            if let image = image {
                APIClient.shared.uploadImage(image, imageName: "OrderSummaryPreviewImage.jpeg", context: .pig, endpoint: "upload/", completion: { (json, error) in
                    
                    defer {
                        DispatchQueue.main.async { self.fetchProductDetails() }
                    }
                    
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    guard let dictionary = json as? [String:AnyObject], let url = dictionary["full"] as? String else {
                        print("OrderSummaryManager: Couldn't parse URL of uploaded image")
                        return
                    }
                    
                    self.coverImageUrl = url
                })
            } else {
                // fetch product details straight away
                print("OrderSummaryManager: Couldn't get image for asset")
                DispatchQueue.main.async { self.fetchProductDetails() }
            }
        })
    }
}
