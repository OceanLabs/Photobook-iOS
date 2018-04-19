//
//  OrderProcessingManager.swift
//  Photobook
//
//  Created by Julian Gruber on 14/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum OrderProcessingError: Error {
    case cancelled
    case upload
    case pdf
    case submission
    case payment
    case server(code: Int, message: String)
}

class OrderProcessingManager {
    
    struct Constants {
        static let isProcessingKey = "OrderProcessingManager.isProcessing"
    }
    
    struct Notifications {
        static let completed = Notification.Name("ly.kite.sdk.orderProcessingManager.completed")
        static let failed = Notification.Name("ly.kite.sdk.orderProcessingManager.failed")
        static let pendingUploadStatusUpdated = Notification.Name("ly.kite.sdk.orderProcessingManager.pendingUploadStatusUpdated")
        static let willFinishOrder = Notification.Name("ly.kite.sdk.orderProcessingManager.willFinishOrder")
    }
    
    private var cancelCompletionBlock:(() -> Void)?
    private var isCancelling:Bool {
        get {
            return cancelCompletionBlock != nil
        }
    }
    
    private(set) var isProcessingOrder:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.isProcessingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.isProcessingKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    static let shared = OrderProcessingManager()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(pendingUploadsChanged), name: PhotobookProduct.pendingUploadStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFinished), name: PhotobookProduct.finishedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFailed), name: PhotobookProduct.failedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldRetryUpload), name: PhotobookProduct.shouldRetryUploadingImages, object: nil)
        
    } //private
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelCompletionBlock = nil
    }
    
    func startProcessing() {
        if isProcessingOrder { return }
        isProcessingOrder = true
        startPhotobookUpload()
    }
    
    func cancelProcessing(completion: @escaping () -> Void) {
        if !isProcessingOrder {
            completion()
        }
        
        if isCancelling {
            cancelCompletionBlock = completion
            return
        }
        
        cancelCompletionBlock = completion
        if ProductManager.shared.currentProduct?.isUploading ?? false {
            product.cancelPhotobookUpload { [weak welf = self] in
                welf?.isProcessingOrder = false
                welf?.cancelCompletionBlock?()
                welf?.cancelCompletionBlock = nil
            }
        } else {
            cancelCompletionBlock?()
            cancelCompletionBlock = nil
        }
    }
    
    func startPhotobookUpload() {
        product.startPhotobookUpload { (count, error) in
            if error != nil {
                Analytics.shared.trackError(.imageUpload)
                NotificationCenter.default.post(name: Notifications.failed, object: self, userInfo: ["error": OrderProcessingError.upload])
            }
        }
    }
    
    func finishOrder() {
        
        NotificationCenter.default.post(name: Notifications.willFinishOrder, object: self)
        
        // 1 - Create PDF
        product.createPhotobookPdf { [weak welf = self] (urls, error) in
            
            if let swelf = welf, swelf.isCancelling {
                swelf.isProcessingOrder = false
                swelf.cancelCompletionBlock?()
                swelf.cancelCompletionBlock = nil
                return
            }
            
            guard let urls = urls else {
                // Failure - PDF
                Analytics.shared.trackError(.pdfCreation)
                NotificationCenter.default.post(name: Notifications.failed, object: welf, userInfo: ["error": OrderProcessingError.pdf])
                return
            }
            
            // 2 - Submit order
            OrderManager.shared.submitOrder(urls, completionHandler: { [weak welf = self] (errorMessage) in
                
                if let swelf = welf, swelf.isCancelling {
                    swelf.isProcessingOrder = false
                    swelf.cancelCompletionBlock?()
                    swelf.cancelCompletionBlock = nil
                    return
                }
                
                if errorMessage != nil {
                    // Failure - Submission
                    Analytics.shared.trackError(.orderSubmission)
                    NotificationCenter.default.post(name: Notifications.failed, object: welf, userInfo: ["error": OrderProcessingError.submission])
                    return
                }
                
                // 3 - Check for order success
                welf?.pollOrderSuccess(completion: { [weak welf = self] (errorMessage) in
                    
                    if let swelf = welf, swelf.isCancelling {
                        swelf.isProcessingOrder = false
                        swelf.cancelCompletionBlock?()
                        swelf.cancelCompletionBlock = nil
                        return
                    }
                    
                    if errorMessage != nil {
                        // Failure - Payment
                        Analytics.shared.trackError(.payment)
                        NotificationCenter.default.post(name: Notifications.failed, object: welf, userInfo: ["error": OrderProcessingError.payment])
                        return
                    }
                    
                    // Success
                    welf?.isProcessingOrder = false
                    NotificationCenter.default.post(name: Notifications.completed, object: self)
                })
            })
        }
    }
    
    private func pollOrderSuccess(completion: @escaping (_ errorMessage:ErrorMessage?) -> Void) {
        //TODO: poll order success and provide option to change payment method if fails
        completion(nil)
    }
    
    //MARK: - Upload
    
    @objc func pendingUploadsChanged() {
        NotificationCenter.default.post(name: Notifications.pendingUploadStatusUpdated, object: self)
    }
    
    @objc func photobookUploadFinished() {
        finishOrder()
    }
    
    @objc func photobookUploadFailed() {
        cancelProcessing() {
            NotificationCenter.default.post(name: Notifications.failed, object: self, userInfo: ["error": OrderProcessingError.cancelled])
        }
    }
    
    @objc func shouldRetryUpload() {
        product.cancelPhotobookUpload {
            NotificationCenter.default.post(name: Notifications.failed, object: self, userInfo: ["error": OrderProcessingError.upload])
        }
    }
}