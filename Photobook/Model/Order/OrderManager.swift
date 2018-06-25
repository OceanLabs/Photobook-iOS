////
//  OrderManager.swift
//  Photobook
//
//  Created by Julian Gruber on 02/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum OrderProcessingError: Error {
    case unknown
    case api(message: ErrorMessage)
    case cancelled
    case upload
    case pdf
    case submission
    case payment
}

protocol OrderProcessingDelegate: class {
    func orderDidComplete(error: OrderProcessingError?)
    func uploadStatusDidUpdate()
    func orderWillFinish()
}

extension OrderProcessingDelegate {
    func orderDidComplete() { orderDidComplete(error: nil) }
}

class OrderManager {
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let basketOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
        static let processingOrderBackupFile = photobookDirectory.appending("ProcessingOrder.dat")
    }
    static let maxNumberOfPollingTries = 60
    
    private lazy var apiManager = PhotobookAPIManager()
    private lazy var kiteApiClient = KiteAPIClient.shared
    private lazy var apiClient = APIClient.shared
    weak var orderProcessingDelegate: OrderProcessingDelegate?
    
    lazy var basketOrder: Order = {
        guard let order = loadOrder(from: Storage.basketOrderBackupFile) else {
            return Order()
        }        
        return order
    }()
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
        
        if loadProcessingOrder() {
            return true
        }
        
        return false
    }
    
    static let shared = OrderManager()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(imageUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
    }
    
    #if DEBUG
    convenience init(apiClient: APIClient) {
        self.init()
        self.apiClient = apiClient
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelCompletionBlock = nil
    }
    
    func reset() {
        basketOrder = Order()
    }
    
    func submitOrder(completionHandler: @escaping (_ error: ErrorMessage?) -> Void) {
        Analytics.shared.trackAction(.orderSubmitted, [Analytics.PropertyNames.secondsSinceAppOpen: Analytics.shared.secondsSinceAppOpen(),
                                                       Analytics.PropertyNames.secondsInBackground: Int(Analytics.shared.secondsSpentInBackground)])
        
        guard let orderParameters = processingOrder?.orderParameters() else {
            completionHandler(ErrorMessage(OrderProcessingError.cancelled))
            return
        }
        
        kiteApiClient.submitOrder(parameters: orderParameters, completionHandler: { [weak welf = self] orderId, error in
            welf?.processingOrder?.orderId = orderId
            completionHandler(error)
        })
    }
    
    private var numberOfTimesPolled = 0
    private func pollOrderStatus(completionHandler: @escaping (_ status: OrderSubmitStatus, _ error: ErrorMessage?) -> Void) {
        guard let receipt = processingOrder?.orderId,
            numberOfTimesPolled < OrderManager.maxNumberOfPollingTries else {
                completionHandler(.error, ErrorMessage(.generic))
            return
        }
        
        kiteApiClient.checkOrderStatus(receipt: receipt) { [weak welf = self] (status, errorMessage, orderId) in
            if let error = errorMessage {
                completionHandler(status, error)
                return
            }
            
            if status == .accepted || status == .received {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    welf?.pollOrderStatus(completionHandler: completionHandler)
                })
                return
            }
            
            welf?.numberOfTimesPolled = 0
            if let orderId = orderId, let processingOrder = welf?.processingOrder {
                processingOrder.orderId = orderId
            }
            
            completionHandler(status, nil)
        }
    }
    
    /// Saves the basket order to disk
    func saveBasketOrder() {
        saveOrder(basketOrder, file: Storage.basketOrderBackupFile)
    }
    
    func applyUpsellsToOrder(_ order: Order) {
        for product in order.products {
            guard let upsoldTemplate = product.upsoldTemplate,
                  product.template != upsoldTemplate else { continue }
            ProductManager.shared.setProduct(product, with: upsoldTemplate)
        }
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
    
    /// Loads the order whose upload is currently in progress and resumes the upload process
    ///
    /// - Parameter completionHandler: Called when the order is loaded, or immediately if there is no order to load
    /// - Returns: True if an order was loaded, false otherwise
    func loadProcessingOrder(_ completionHandler: (() -> Void)? = nil) -> Bool {
        guard FileManager.default.fileExists(atPath: Storage.processingOrderBackupFile),
            let order = loadOrder(from: Storage.processingOrderBackupFile)
            else {
                completionHandler?()
                return false
        }
        
        processingOrder = order
        APIClient.shared.recreateBackgroundSession()
        completionHandler?()
        return true
    }
    
    func hasPendingUploads(_ completionHandler: @escaping ((Bool) -> Void)) {
        apiClient.pendingBackgroundTaskCount { (count) in
            completionHandler(count > 0)
        }
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
            uploadAsset(asset: asset, failureHandler: { [weak welf = self] error in
                welf?.failedUpload(with: error)
            })
        }
    }
    
    func finishOrder() {

        // Multiple uploads are not supported. Pick first photobook.
        guard let photobook = processingOrder?.products.first else {
            orderProcessingDelegate?.orderDidComplete(error: .unknown)
            return
        }

        orderProcessingDelegate?.orderWillFinish()
        
        // 1 - Create PDF
        apiManager.createPdf(withPhotobook: photobook) { [weak welf = self] (urls, error) in
            
            if let swelf = welf, swelf.isCancelling {
                swelf.processingOrder = nil
                swelf.cancelCompletionBlock?()
                swelf.cancelCompletionBlock = nil
                return
            }
            
            guard let urls = urls else {
                // Failure - PDF
                Analytics.shared.trackError(.pdfCreation)
                welf?.orderProcessingDelegate?.orderDidComplete(error: .pdf)
                return
            }
            
            photobook.setPdfUrls(urls)
            
            // 2 - Submit order
            welf?.submitOrder(completionHandler: { [weak welf = self] (errorMessage) in
                
                if let swelf = welf, swelf.isCancelling {
                    swelf.processingOrder = nil
                    swelf.cancelCompletionBlock?()
                    swelf.cancelCompletionBlock = nil
                    return
                }
                
                if let errorMessage = errorMessage {
                    Analytics.shared.trackError(.orderSubmission)
                    welf?.orderProcessingDelegate?.orderDidComplete(error: .api(message: errorMessage))
                    return
                }
                
                // 3 - Check for order success
                welf?.pollOrderStatus { [weak welf = self] (status, errorMessage) in
                    
                    if let swelf = welf, swelf.isCancelling {
                        swelf.processingOrder = nil
                        swelf.cancelCompletionBlock?()
                        swelf.cancelCompletionBlock = nil
                        return
                    }    
                    
                    if status == .paymentError {
                        Analytics.shared.trackError(.payment)
                        welf?.orderProcessingDelegate?.orderDidComplete(error: .payment)
                        return
                    }
                    
                    if let errorMessage = errorMessage {
                        Analytics.shared.trackError(.payment)
                        welf?.orderProcessingDelegate?.orderDidComplete(error: .api(message: errorMessage))
                        return
                    }
                    
                    // Success
                    welf?.processingOrder = nil
                    welf?.orderProcessingDelegate?.orderDidComplete()
                }
            })
        }
    }
    
    //MARK: - Upload
    
    func uploadAsset(asset: Asset, failureHandler: @escaping (Error) -> Void) {
        asset.imageData(progressHandler: nil, completionHandler: { [weak welf = self] data, fileExtension, error in
            guard error == nil, let data = data, fileExtension != .unsupported else {
                failureHandler(PhotobookAPIError.missingPhotobookInfo)
                return
            }
            
            if let fileUrl = DiskUtils.saveDataToCachesDirectory(data: data, name: "\(asset.fileIdentifier).\(fileExtension.string())") {
                welf?.apiClient.uploadImage(fileUrl, reference: PhotobookAPIManager.imageUploadIdentifierPrefix + asset.identifier, context: .pig, endpoint: PhotobookAPIManager.EndPoints.imageUpload)
            } else {
                failureHandler(PhotobookAPIError.couldNotSaveTempImageData)
            }
        })
    }
    
    @objc func imageUploadFinished(_ notification: Notification) {
        guard let order = processingOrder else { return }
        
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            failedUpload(with: APIClientError.parsing)
            return
        }
        
        // Check if this is a photobook api manager asset upload
        if let reference = dictionary["task_reference"] as? String, !reference.hasPrefix(PhotobookAPIManager.imageUploadIdentifierPrefix) {
            return
        }
        
        if let error = dictionary["error"] as? APIClientError {
            failedUpload(with: error)
            return
        }
        
        guard let reference = dictionary["task_reference"] as? String, let url = dictionary["full"] as? String else {
            failedUpload(with: APIClientError.parsing)
            return
        }
        
        let referenceId = reference.suffix(reference.count - PhotobookAPIManager.imageUploadIdentifierPrefix.count)
        
        let assets = order.assetsToUpload().filter({ $0.identifier == referenceId })
        guard assets.first != nil else {
            failedUpload(with: PhotobookAPIError.missingPhotobookInfo)
            return
        }
        
        // Store the URL string for all assets with the same id
        for asset in assets {
            asset.uploadUrl = url
        }
        
        orderProcessingDelegate?.uploadStatusDidUpdate()
        saveProcessingOrder()
        
        if order.remainingAssetsToUpload().isEmpty {
            Analytics.shared.trackAction(.uploadSuccessful)
            finishOrder()
        }
    }
    
    private func failedUpload(with error: Error) {
        guard processingOrder != nil else { return }
        
        Analytics.shared.trackError(.imageUpload)
        
        if let error = error as? PhotobookAPIError {
            switch error {
            case .couldNotSaveTempImageData:
                Analytics.shared.trackError(.diskError)

                orderProcessingDelegate?.uploadStatusDidUpdate()
                orderProcessingDelegate?.orderDidComplete(error: .upload)
            case .missingPhotobookInfo, .couldNotBuildCreationParameters:
                // Not resolvable
                Analytics.shared.trackError(.photobookInfo)
                cancelProcessing() {
                    self.orderProcessingDelegate?.orderDidComplete(error: .cancelled)
                }
            default:
                //unknown error or not relevant for image upload. Should never happen. Cancel processing
                orderProcessingDelegate?.orderDidComplete(error: OrderProcessingError.cancelled)
            }
            return
        }
        
        // Connection / server / other errors
        orderProcessingDelegate?.orderDidComplete(error: .upload)
    }
}
