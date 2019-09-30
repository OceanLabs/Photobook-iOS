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

enum OrderProcessingError: Error {
    case unknown
    case api(message: ErrorMessage)
    case cancelled
    case upload
    case uploadProcessing
    case submission
    case payment
    case corruptData
}

protocol OrderProcessingDelegate: class {
    func orderDidComplete(error: OrderProcessingError?)
    func progressDidUpdate()
    func uploadStatusDidUpdate()
    func orderWillFinish()
}

enum OrderDiskManagerError: Error {
    case couldNotSaveTempImageData
}

protocol OrderDiskManager {
    func saveDataToCachesDirectory(data: Data, name: String) -> URL?
}

class DefaultOrderDiskManager: OrderDiskManager {
    func saveDataToCachesDirectory(data: Data, name: String) -> URL? {
        return DiskUtils.saveDataToCachesDirectory(data: data, name: name)
    }
}

class OrderManager {
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let basketOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
        static let processingOrderBackupFile = photobookDirectory.appending("ProcessingOrder.dat")
        static let automaticRetryCountKey = "AutomaticRetryCount"
    }
    static let maxNumberOfAutomaticRetries = 20
    static let maxNumberOfPollingTries = 60
    
    private lazy var kiteApiClient = KiteAPIClient.shared
    private lazy var apiClient = APIClient.shared
    private lazy var assetLoadingManager = AssetLoadingManager.shared
    private lazy var orderDiskManager: OrderDiskManager = DefaultOrderDiskManager()

    private var internalAutomaticRetryCount: Int!
    private var automaticRetryCount: Int {
        get {
            if internalAutomaticRetryCount == nil {
                internalAutomaticRetryCount = UserDefaults.standard.integer(forKey: Storage.automaticRetryCountKey)
            }
            return internalAutomaticRetryCount
        }
        set {
            internalAutomaticRetryCount = newValue
            UserDefaults.standard.set(internalAutomaticRetryCount, forKey: Storage.automaticRetryCountKey)
        }
    }

    weak var orderProcessingDelegate: OrderProcessingDelegate?
    let prioritizedCurrencyCodes: [String] = {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") {
            return ["GBP"]
        }
        var codes = ["USD", "GBP", "EUR"]
        if let localeCurrency = Locale.current.currencyCode {
            codes.insert(localeCurrency, at: 0)
        }
        return codes
    }()
    var preferredCurrencyCode: String {
       return prioritizedCurrencyCodes.first!
    }
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(fileUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fileUploadProgress(_:)), name: APIClient.backgroundSessionTaskUploadProgress, object: nil)
    }
    
    #if DEBUG
    convenience init(apiClient: APIClient, kiteApiClient: KiteAPIClient, assetLoadingManager: AssetLoadingManager, orderDiskManager: OrderDiskManager) {
        self.init()
        self.apiClient = apiClient
        self.kiteApiClient = kiteApiClient
        self.assetLoadingManager = assetLoadingManager
        self.orderDiskManager = orderDiskManager
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelCompletionBlock = nil
    }
    
    func reset() {
        basketOrder = Order()
        saveBasketOrder()
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
        
        let saved = NSKeyedArchiver.archiveRootObject(data, toFile: file)
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
        apiClient.recreateBackgroundSession()
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
            print("OrderManager: failed to unarchive order")
            return nil
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            print("OrderManager: decoding of order failed")
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
            return
        }
        
        if isCancelling {
            cancelCompletionBlock = completion
            return
        }
        
        cancelCompletionBlock = completion
        apiClient.cancelBackgroundTasks { [weak welf = self] in
            guard let stelf = welf else { return }
            
            stelf.processingOrder = nil
            stelf.automaticRetryCount = 0
            stelf.cancelCompletionBlock?()
            stelf.cancelCompletionBlock = nil
        }
    }
    
    /// Uploads the assets
    func uploadAssets() {
        guard let processingOrder = processingOrder else { return }
        
        // If all assets have already been uploaded, jump to finishing the order
        let assetsToUpload = processingOrder.remainingAssetsToUpload()
        guard !assetsToUpload.isEmpty else {
            Analytics.shared.trackAction(.uploadSuccessful)
            automaticRetryCount = 0
            finishOrder()
            return
        }
        
        orderProcessingDelegate?.uploadStatusDidUpdate()
        
        // Upload images
        uploadTaskProgress = [String: Double]()
        apiClient.updateTaskReferences { [weak welf = self] in
            for asset in assetsToUpload {
                welf?.uploadAsset(asset: asset)
            }
        }
    }
    
    private func submitOrder(completionHandler: @escaping (_ error: APIClientError?) -> Void) {
        Analytics.shared.trackAction(.orderSubmitted, [Analytics.PropertyNames.secondsSinceAppOpen: Analytics.shared.secondsSinceAppOpen(),
                                                       Analytics.PropertyNames.secondsInBackground: Int(Analytics.shared.secondsSpentInBackground)])
        
        guard let orderParameters = processingOrder?.orderParameters() else {
            completionHandler(.parsing(details: "SubmitOrder: Could not parse order parameters"))
            return
        }
        
        kiteApiClient.submitOrder(parameters: orderParameters, completionHandler: { [weak welf = self] result in
            guard let processingOrder = welf?.processingOrder else { return }
            switch result {
            case .success(let orderId):
                processingOrder.orderId = orderId
                completionHandler(nil)
            case .failure(let error):
                completionHandler(error)
            }
        })
    }
    
    private var numberOfTimesPolled = 0
    private func pollOrderStatus(completionHandler: @escaping (Error?) -> Void) {
        guard let receipt = processingOrder?.orderId,
            numberOfTimesPolled < OrderManager.maxNumberOfPollingTries else {
                completionHandler(APIClientError.generic)
                return
        }
        
        kiteApiClient.checkOrderStatus(receipt: receipt) { [weak welf = self] result in
            guard let stelf = welf else { return }
            if case .failure(let error) = result {
                completionHandler(error)
                return
            }
            let (status, orderId) = try! result.get()
            
            if status == .accepted || status == .received {
                stelf.numberOfTimesPolled += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    stelf.pollOrderStatus(completionHandler: completionHandler)
                })
                return
            }
            
            stelf.numberOfTimesPolled = 0
            if let orderId = orderId, let processingOrder = stelf.processingOrder {
                processingOrder.orderId = orderId
            }
            
            completionHandler(nil)
        }
    }

    private var isSubmittingOrder = false
    func finishOrder() {
        guard let products = processingOrder?.products else { return }
        
        orderProcessingDelegate?.orderWillFinish()
        
        let pdfGenerationDispatchGroup = DispatchGroup()
        
        for product in products {
            // Process uploaded assets
            pdfGenerationDispatchGroup.enter()
            product.processUploadedAssets(completionHandler: { [weak welf = self] error in
                guard let stelf = welf else { return }
                
                if stelf.isCancelling {
                    stelf.processingOrder = nil
                    stelf.cancelCompletionBlock?()
                    stelf.cancelCompletionBlock = nil
                    return
                }
                
                guard error == nil else {
                    stelf.orderProcessingDelegate?.orderDidComplete(error: .uploadProcessing)
                    return
                }
                
                pdfGenerationDispatchGroup.leave()
            })
        }
        
        pdfGenerationDispatchGroup.notify(queue: DispatchQueue.main, execute: { [weak welf = self] in
            guard let stelf = welf, stelf.processingOrder != nil, !stelf.isSubmittingOrder else { return }
            
            // Submit order
            stelf.isSubmittingOrder = true
            stelf.submitOrder(completionHandler: { [weak welf = self] (error) in
                guard let stelf = welf else { return }
                
                if stelf.isCancelling {
                    stelf.processingOrder = nil
                    stelf.cancelCompletionBlock?()
                    stelf.cancelCompletionBlock = nil
                    stelf.isSubmittingOrder = false
                    return
                }
                
                if let error = error {
                    // Something went wrong while parsing the order parameters or response. Order should be cancelled.
                    if case APIClientError.parsing(let details) = error {
                        Analytics.shared.trackError(.parsing, details)
                        stelf.orderDidComplete(error: .cancelled)
                    } else {
                        // Non-critical error. Tell the user and allow retrying.
                        if case APIClientError.server(let code, let message) = error {
                            Analytics.shared.trackError(.orderSubmission, "Server error: \(message) (\(code))")
                        }
                        stelf.orderDidComplete(error: OrderProcessingError.api(message: ErrorMessage(error)))
                    }
                    return
                }
                
                // Check for order success
                welf?.numberOfTimesPolled = 0
                welf?.pollOrderStatus { [weak welf = self] error in
                    guard let stelf = welf else { return }
                    
                    if stelf.isCancelling {
                        stelf.processingOrder = nil
                        stelf.cancelCompletionBlock?()
                        stelf.cancelCompletionBlock = nil
                        stelf.isSubmittingOrder = false
                        return
                    }
                    
                    if let error = error {
                        switch error {
                        case APIClientError.parsing(let details):
                            Analytics.shared.trackError(.parsing, details)
                        case APIClientError.server(let code, let message):
                            Analytics.shared.trackError(.payment, "Server error: \(message) (\(code))")
                        case KiteAPIClientError.paymentError:
                            Analytics.shared.trackError(.payment)
                            stelf.orderDidComplete(error: .payment)
                            return
                        default:
                            break
                        }

                        stelf.orderDidComplete(error: .api(message: ErrorMessage(error)))
                        return
                    }
                    
                    // Success
                    Analytics.shared.trackAction(.orderCompleted, ["orderId": welf?.processingOrder?.orderId ?? ""])
                    stelf.processingOrder = nil
                    stelf.orderDidComplete()
                }
            })
        })
    }
    
    private func orderDidComplete(error: OrderProcessingError? = nil) {
        orderProcessingDelegate?.orderDidComplete(error: error)
        isSubmittingOrder = false
    }
    
    // MARK: - Upload
    private func uploadAsset(asset: Asset) {
        // If it is a PDFAsset, skip retrieving an asset image and upload the PDF instead
        if let pdfAsset = asset as? PDFAsset {
            kiteApiClient.requestSignedUrl(for: .pdf) { [weak welf = self] result in
                guard let stelf = welf else { return }
                if case .failure(let error) = result {
                    stelf.failedFileUpload(with: error)
                    return
                }
                let (signedUrl, fileUrl) = try! result.get()
                
                pdfAsset.fileUrl = fileUrl // Store final URL pending upload
                stelf.apiClient.uploadPdf(pdfAsset.filePath, to: signedUrl, reference: pdfAsset.identifier)
            }
            return
        }
        
        assetLoadingManager.imageData(for: asset, progressHandler: nil, completionHandler: { [weak welf = self] data, fileExtension, error in
            guard error == nil, let imageData = data else {
                if let error = error {
                    welf?.failedFileUpload(with: error)
                } else {
                    // Unlikely to happen
                    welf?.failedFileUpload(with: AssetLoadingException.notFound)
                }
                return
            }
            
            if let fileUrl = welf?.orderDiskManager.saveDataToCachesDirectory(data: imageData, name: "\(asset.fileIdentifier).\(fileExtension.string())") {
                welf?.apiClient.uploadImage(fileUrl, reference: asset.identifier)
            } else {
                welf?.failedFileUpload(with: OrderDiskManagerError.couldNotSaveTempImageData)
            }
        })
    }

    private var uploadTaskProgress = [String: Double]()
    var uploadProgress: Double {
        guard isProcessingOrder else { return 0.0 }
        let uploaded = processingOrder!.uploadedAssets()
        
        let currentProgress = uploadTaskProgress.reduce(0) { (result, keyValue) -> Double in
            let (key, value) = keyValue
            if !uploaded.contains(where: { $0.identifier == key }) {
                return result + value
            }
            return result
        }
        
        return currentProgress + Double(uploaded.count)
    }

    @objc private func fileUploadProgress(_ notification: Notification) {
        guard processingOrder != nil else { return }
        
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            failedFileUpload(with: APIClientError.parsing(details: "FileUploadProgress: UserInfo not a dictionary"))
            return
        }

        // Check if this is a photobook api manager asset upload
        guard let reference = dictionary["task_reference"] as? String,
            reference.hasPrefix(apiClient.imageUploadIdentifierPrefix) || reference.hasPrefix(apiClient.fileUploadIdentifierPrefix),
            let progress = dictionary["progress"] as? Double
        else {
            return
        }

        let referenceId = reference.replacingOccurrences(of: apiClient.imageUploadIdentifierPrefix, with: "").replacingOccurrences(of: apiClient.fileUploadIdentifierPrefix, with: "")
        uploadTaskProgress[referenceId] = progress
        
        orderProcessingDelegate?.progressDidUpdate()
    }
    
    @objc private func fileUploadFinished(_ notification: Notification) {
        guard let order = processingOrder else { return }
        
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            failedFileUpload(with: APIClientError.parsing(details: "FileUploadFinished: UserInfo not a dictionary"))
            return
        }
        
        // Check if this is a photobook api manager asset upload
        if let reference = dictionary["task_reference"] as? String,
           !reference.hasPrefix(apiClient.imageUploadIdentifierPrefix) && !reference.hasPrefix(apiClient.fileUploadIdentifierPrefix) {
            return
        }
        
        if let error = dictionary["error"] as? APIClientError {
            failedFileUpload(with: error)
            return
        }
        
        // Check that a task reference is returned
        guard let reference = dictionary["task_reference"] as? String else {
            let details = "FileUploadFinished: Upload task reference missing"
            failedFileUpload(with: APIClientError.parsing(details: details))
            return
        }

        // If it is an image upload, check that a URL was returned
        let url = dictionary["full"] as? String
        if reference.hasPrefix(apiClient.imageUploadIdentifierPrefix), url == nil {
            let details = "FileUploadFinished: Image upload \(reference) full url missing"
            failedFileUpload(with: APIClientError.parsing(details: details))
            return
        }
        
        let referenceId = reference.replacingOccurrences(of: apiClient.imageUploadIdentifierPrefix, with: "").replacingOccurrences(of: apiClient.fileUploadIdentifierPrefix, with: "")
        
        let assets = order.allAssets().filter({ $0.identifier == referenceId })
        guard assets.first != nil else {
            failedFileUpload(with: AssetLoadingException.unsupported(details: "FileUploadFinished: Could not match asset reference \(referenceId)"))
            return
        }
        
        // Store the URL string for all assets with the same id
        for var asset in assets {
            // If it is a pdfAsset, confirm the upload
            if let pdfAsset = asset as? PDFAsset {
                pdfAsset.confirmUpload()
            } else {
                asset.uploadUrl = url
            }
        }
        
        orderProcessingDelegate?.progressDidUpdate()
        saveProcessingOrder()
        
        if order.remainingAssetsToUpload().isEmpty {
            orderProcessingDelegate?.uploadStatusDidUpdate()
            
            Analytics.shared.trackAction(.uploadSuccessful)
            finishOrder()
            return
        }

        relaunchUploadsIfNeeded()
    }
    
    private func failedFileUpload(with error: Error) {
        guard processingOrder != nil else { return }
        
        if let error = error as? OrderDiskManagerError {
            switch error {
            case .couldNotSaveTempImageData:
                Analytics.shared.trackError(.diskError)
            }
        }

        if let error = error as? AssetLoadingException, case .unsupported(let details) = error {
            Analytics.shared.trackError(.productInfo, details)
            cancelProcessing() {
                self.orderProcessingDelegate?.orderDidComplete(error: .cancelled)
            }
            return
        }

        // Connection / server / other errors
        if let error = error as? APIClientError, case .parsing(let details) = error {
            Analytics.shared.trackError(.parsing, details)
        }

        relaunchUploadsIfNeeded()
    }
    
    private func relaunchUploadsIfNeeded() {
        apiClient.pendingBackgroundTaskCount { [weak welf = self] (count) in
            // Check if all tasks have finished and retry if needed. Used 1 instead of 0 because of cancellation delays on tasks.
            if count <= 1 {
                welf?.automaticRetryCount += 1
                if (welf?.automaticRetryCount ?? 0) > OrderManager.maxNumberOfAutomaticRetries {
                    welf?.apiClient.cancelBackgroundTasks({
                        welf?.orderProcessingDelegate?.orderDidComplete(error: .upload)
                        welf?.orderProcessingDelegate?.uploadStatusDidUpdate()
                    })
                    return
                }
                welf?.uploadAssets()
            }
        }
    }
}
