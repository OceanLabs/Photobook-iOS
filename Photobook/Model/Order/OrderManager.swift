////
//  OrderManager.swift
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
    
    struct NotificationName {
        static let completed = Notification.Name("ly.kite.sdk.orderManager.completed")
        static let failed = Notification.Name("ly.kite.sdk.orderManager.failed")
        static let pendingUploadStatusUpdated = Notification.Name("ly.kite.sdk.orderManager.pendingUploadStatusUpdated")
        static let willFinishOrder = Notification.Name("ly.kite.sdk.orderManager.willFinishOrder")
        static let shouldRetryUploadingImages = Notification.Name("ly.kite.sdk.orderManager.ShouldRetryUploadingImages")
        static let finishedPhotobookCreation = Notification.Name("ly.kite.sdk.orderManager.FinishedPhotobookCreation")
    }
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let basketOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
        static let processingOrderBackupFile = photobookDirectory.appending("ProcessingOrder.dat")
    }
    
    private lazy var apiManager = PhotobookAPIManager()
    
    lazy var basketOrder = Order()
    var processingOrder: Order? {
        didSet {
            guard let _ = processingOrder else {
                try? FileManager.default.removeItem(atPath: Storage.processingOrderBackupFile)
                return
            }
            
            saveProcessingOrder()
        }
    }
    
    private var cancelCompletionBlock:(() -> Void)?
    private var isCancelling: Bool {
        return cancelCompletionBlock != nil
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
    
    static let shared = OrderManager()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(shouldRetryUpload), name: NotificationName.shouldRetryUploadingImages, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
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
    
    func saveProcessingOrder() {
        guard let processingOrder = processingOrder else { return }
        
        saveOrder(processingOrder, file: Storage.processingOrderBackupFile)
    }
    
    /// Loads the basket order from disk and returns it
    func loadBasketOrder() -> Order? {
        guard let order = loadOrder(from: Storage.basketOrderBackupFile) else { return nil }
        
        basketOrder = order
        return order
    }
    
    func loadProcessingOrder() -> Order? {
        guard FileManager.default.fileExists(atPath: Storage.processingOrderBackupFile),
            let order = loadOrder(from: Storage.processingOrderBackupFile)
            else { return nil }
        
        processingOrder = order
        APIClient.shared.recreateBackgroundSession()
        uploadAssets()
        return order
    }
    
    private func loadOrder(from file: String) -> Order? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: file) as? Data else {
            #if DEBUG
            print("OrderManager: failed to unarchive order")
            #endif
            return nil
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            #if DEBUG
            print("OrderManager: decoding of order failed")
            #endif
            return nil
        }
        
        return unarchivedOrder
    }
    
    // MARK: - Order Uploading
    
    func startProcessing(order: Order) {
        if isProcessingOrder { return }
        processingOrder = order
        uploadAssets()
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
        APIClient.shared.cancelBackgroundTasks { [weak welf = self] in
            welf?.processingOrder = nil
            welf?.cancelCompletionBlock?()
            welf?.cancelCompletionBlock = nil
        }
    }
    
    /// Uploads the assets
    func uploadAssets() {
        
        let assetsToUpload = processingOrder!.assetsToUpload()
        
        // Upload images
        for asset in assetsToUpload {
            apiManager.uploadAsset(asset: asset, failureHandler: { [weak welf = self] error in
                welf?.didFailUpload(error)
            })
            
        }
    }
    
    func finishOrder() {
        
        NotificationCenter.default.post(name: NotificationName.willFinishOrder, object: self)
        
        // 1 - Create PDF
        apiManager.createPhotobookPdf { [weak welf = self] (urls, error) in
            
            if let swelf = welf, swelf.isCancelling {
                swelf.processingOrder = nil
                swelf.cancelCompletionBlock?()
                swelf.cancelCompletionBlock = nil
                return
            }
            
            guard let urls = urls else {
                // Failure - PDF
                Analytics.shared.trackError(.pdfCreation)
                NotificationCenter.default.post(name: NotificationName.failed, object: welf, userInfo: ["error": OrderProcessingError.pdf])
                return
            }
            
            // 2 - Submit order
            welf?.submitOrder(urls, completionHandler: { [weak welf = self] (errorMessage) in
                
                if let swelf = welf, swelf.isCancelling {
                    swelf.processingOrder = nil
                    swelf.cancelCompletionBlock?()
                    swelf.cancelCompletionBlock = nil
                    return
                }
                
                if errorMessage != nil {
                    // Failure - Submission
                    Analytics.shared.trackError(.orderSubmission)
                    NotificationCenter.default.post(name: NotificationName.failed, object: welf, userInfo: ["error": OrderProcessingError.submission])
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
                        NotificationCenter.default.post(name: NotificationName.failed, object: welf, userInfo: ["error": OrderProcessingError.payment])
                        return
                    }
                    
                    // Success
                    welf?.processingOrder = nil
                    NotificationCenter.default.post(name: NotificationName.completed, object: self)
                })
            })
        }
    }
    
    private func pollOrderSuccess(completion: @escaping (_ errorMessage:ErrorMessage?) -> Void) {
        //TODO: poll order success and provide option to change payment method if fails
        completion(nil)
    }
    
    //MARK: - Upload
    
    @objc func shouldRetryUpload()  {
        NotificationCenter.default.post(name: NotificationName.failed, object: self, userInfo: ["error": OrderProcessingError.upload])
    }
    
    @objc func imageUploadFinished(_ notification: Notification) {
        guard let order = processingOrder else { return }
        
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            print("PhotobookAPIManager: Task finished but could not cast user info")
            return
        }
        
        //check if this is a photobook api manager asset upload
        if let reference = dictionary["task_reference"] as? String, !reference.hasPrefix(PhotobookAPIManager.imageUploadIdentifierPrefix) {
            //not intended for this class
            return
        }
        
        if let error = dictionary["error"] as? APIClientError {
           didFailUpload(error)
            return
        }
        
        guard let reference = dictionary["task_reference"] as? String,
            let url = dictionary["full"] as? String else {
                
                didFailUpload(APIClientError.parsing)
                return
        }
        let referenceId = reference.suffix(reference.count - PhotobookAPIManager.imageUploadIdentifierPrefix.count)
        
        let assets = order.assetsToUpload().filter({ $0.identifier == referenceId })
        guard let firstAsset = assets.first else {
            didFailUpload(PhotobookAPIError.missingPhotobookInfo)
            return
        }
        
        // Store the URL string for all assets with the same id
        for asset in assets {
            asset.uploadUrl = url
        }
        
        let remainingAssets = order.remainingAssetsToUpload()
        
        let info: [String: Any] = ["asset": firstAsset, "pending": remainingAssets.count]
        NotificationCenter.default.post(name: NotificationName.pendingUploadStatusUpdated, object: info)
        saveProcessingOrder()
        
        if remainingAssets.isEmpty {
            finishUploadingPhotobook()
        }
    }
    
    private func didFailUpload(_ error: Error) {
        guard let order = processingOrder else { return }
        
        Analytics.shared.trackError(.imageUpload)
        NotificationCenter.default.post(name: NotificationName.failed, object: self, userInfo: ["error": OrderProcessingError.upload])
        
        if let error = error as? PhotobookAPIError {
            switch error {
            case .couldNotSaveTempImageData:
                Analytics.shared.trackError(.diskError)
                let info = [ "pending": order.remainingAssetsToUpload().count ]
                NotificationCenter.default.post(name: NotificationName.pendingUploadStatusUpdated, object: info)
                NotificationCenter.default.post(name: NotificationName.shouldRetryUploadingImages, object: nil) //resolvable
            case .missingPhotobookInfo, .couldNotBuildCreationParameters:
                uploadFailed() //not resolvable
            }
        } else if let _ = error as? APIClientError {
            // Connection / server errors or parsing error
            NotificationCenter.default.post(name: NotificationName.shouldRetryUploadingImages, object: nil) //resolvable
        }
    }
    
    private func finishUploadingPhotobook() {
        Analytics.shared.trackAction(.uploadSuccessful)
        finishOrder()
    }
    
    private func uploadFailed() {
        Analytics.shared.trackError(.photobookInfo)
        cancelProcessing() {
            NotificationCenter.default.post(name: NotificationName.failed, object: self, userInfo: ["error": OrderProcessingError.cancelled])
        }
    }
    
    private func createPdf() {
        NotificationCenter.default.post(name: NotificationName.finishedPhotobookCreation, object: nil)
    }
    
}
