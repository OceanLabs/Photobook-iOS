////
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 02/02/2018.
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

class OrderManager {
    
    struct Notifications {
        static let completed = Notification.Name("ly.kite.sdk.OrderManager.completed")
        static let failed = Notification.Name("ly.kite.sdk.OrderManager.failed")
        static let pendingUploadStatusUpdated = Notification.Name("ly.kite.sdk.OrderManager.pendingUploadStatusUpdated")
        static let willFinishOrder = Notification.Name("ly.kite.sdk.OrderManager.willFinishOrder")
    }
    
    struct Storage { //TODO: make private
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let photobookBackupFile = photobookDirectory.appending("Photobook.dat") //TODO: remove
        static let basketOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
        static let processingOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
    }
    
    lazy var basketOrder = Order()
    var processingOrder: Order? {
        didSet {
            guard let processingOrder = processingOrder else {
                try? FileManager.default.removeItem(atPath: Storage.processingOrderBackupFile)
                return
            }
            
            saveOrder(processingOrder, file: Storage.processingOrderBackupFile)
        }
    }
    
    private var cancelCompletionBlock:(() -> Void)?
    private var isCancelling: Bool {
        get {
            return cancelCompletionBlock != nil
        }
    }
    
    var isProcessingOrder: Bool {
        if processingOrder != nil {
            return true
        }
        
        if let _ = loadProcessingOrder() {
            return true
        }
        
        return false
    }
    
    private var product: PhotobookProduct! {
        return basketOrder.items.first
    }
    
    static let shared = OrderManager()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(pendingUploadsChanged), name: PhotobookProduct.pendingUploadStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFinished), name: PhotobookProduct.finishedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFailed), name: PhotobookProduct.failedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldRetryUpload), name: PhotobookProduct.shouldRetryUploadingImages, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelCompletionBlock = nil
    }
    
    func reset() {
        basketOrder = Order()
    }
    
    func submitOrder(_ urls:[String], completionHandler: @escaping (_ error: ErrorMessage?) -> Void) {
    
        Analytics.shared.trackAction(.orderSubmitted, [Analytics.PropertyNames.secondsSinceAppOpen: Analytics.shared.secondsSinceAppOpen(),
                                                       Analytics.PropertyNames.secondsInBackground: Int(Analytics.shared.secondsSpentInBackground)
            ])
        
        //TODO: change to accept two pdf urls
        KiteAPIClient.shared.submitOrder(parameters: basketOrder.orderParameters(), completionHandler: { [weak welf = self] orderId, error in
            welf?.basketOrder.orderId = orderId
            completionHandler(error)
        })
    }
    
    /// Saves the basket order to disk
    func saveBasketOrder() {
        saveOrder(basketOrder, file: Storage.basketOrderBackupFile)
    }
    
    private func saveOrder(_ order: Order, file: String) {
        guard let data = try? PropertyListEncoder().encode(order) else {
            fatalError("OrderManager: encoding of order failed")
        }
        
        if !FileManager.default.fileExists(atPath: Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("OrderManager: could not save order")
            }
        }
        
        let saved = NSKeyedArchiver.archiveRootObject(data, toFile:file )
        if !saved {
            print("OrderManager: failed to archive order")
        }
    }
    
    /// Loads the basket order from disk and returns it
    func loadBasketOrder() -> Order? {
        guard let order = loadOrder(from: Storage.basketOrderBackupFile) else { return nil }
        
        basketOrder = order
        return order
    }
    
    private func loadProcessingOrder() -> Order? {
        guard let order = loadOrder(from: Storage.processingOrderBackupFile) else { return nil }
        
        processingOrder = order
        return order
    }
    
    private func loadOrder(from file: String) -> Order? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: file) as? Data else {
            print("ProductManager: failed to unarchive order")
            return nil
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            print("ProductManager: decoding of order failed")
            return nil
        }
        
        return unarchivedOrder
    }
    
    // MARK: - Order Uploading
    
    func startProcessing(order: Order) {
        if isProcessingOrder { return }
        processingOrder = order
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
                welf?.processingOrder = nil
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
                swelf.processingOrder = nil
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
                    swelf.processingOrder = nil
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
                        swelf.processingOrder = nil
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
                    welf?.processingOrder = nil
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

