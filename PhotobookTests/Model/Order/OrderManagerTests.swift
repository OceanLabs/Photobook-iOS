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

import XCTest
import Photos
@testable import Photobook

class OrderManagerTests: XCTestCase {

    var productManager: ProductManager!
    
    let photosAsset = PhotosAssetMock()
    
    var apiClient: APIClientMock!
    var kiteApiClient: KiteAPIClientMock!
    var photobookApiManager: PhotobookAPIManagerMock!
    var assetLoadingManager: AssetLoadingManagerMock!
    var orderDiskManager: OrderDiskManagerMock!
    var testOrderProcessingDelegate: OrderProcessingDelegateMock!
    var order: OrderMock!
    
    // SUT
    var orderManager: OrderManager!

    override func setUp() {
        super.setUp()
        
        apiClient = APIClientMock()
        kiteApiClient = KiteAPIClientMock()
        photobookApiManager = PhotobookAPIManagerMock()
        orderDiskManager = OrderDiskManagerMock()
        
        // Setup a fake product
        apiClient.response = JSON.parse(file: "photobooks")
        productManager = ProductManager(apiManager: PhotobookAPIManager(apiClient: apiClient))
        productManager.initialise(completion: nil)
        
        _ = productManager.setCurrentProduct(with: productManager.products!.first!, assets: [])
        
        productManager.currentProduct?.productLayouts = [ProductLayout]()
        
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.01, y: 0.01, width: 0.5, height: 0.1))
        let layout = Layout(id: 1, category: "portrait", imageLayoutBox: layoutBox, textLayoutBox: layoutBox, isDoubleLayout: false)
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = photosAsset
        productLayoutAsset.containerSize = CGSize(width: 12.0, height: 14.0)
        
        let productLayoutText = ProductLayoutText()
        productLayoutText.text = "Tests are groovy"
        
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: productLayoutText)

        productManager.currentProduct?.productLayouts.append(productLayout)
        
        // Set up the order
        let product = productManager.currentProduct!
        product.photobookApiManager = photobookApiManager
        
        order = OrderMock()
        order.products = [product]
        order.orderParametersStub = ["order": "1"]

        testOrderProcessingDelegate = OrderProcessingDelegateMock()
        assetLoadingManager = AssetLoadingManagerMock()
        
        // Create OrderManager
        orderManager = OrderManager(apiClient: apiClient, kiteApiClient: kiteApiClient, assetLoadingManager: assetLoadingManager, orderDiskManager: orderDiskManager)
        orderManager.processingOrder = order
        orderManager.orderProcessingDelegate = testOrderProcessingDelegate
    }
    
    override func tearDown() {
        orderManager.processingOrder = nil
    }

    func testSaveBasketOrder() {
        let product = productManager.currentProduct!
        
        OrderManager.shared.basketOrder.products = [product]
        OrderManager.shared.saveBasketOrder()
        
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/BasketOrder.dat")) as? Data else {
            XCTFail("Decoding of product failed")
            return
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            XCTFail("Decoding of product failed")
            return
        }
        guard let photobookProduct = unarchivedOrder.products.first as? PhotobookProduct else {
            XCTFail("Decoded product is not a photobook")
            return
        }
        
        XCTAssertEqual(photobookProduct.photobookTemplate.id, product.photobookTemplate.id)
        XCTAssertEqual(photobookProduct.photobookTemplate.name, product.photobookTemplate.name)
        XCTAssertEqual(photobookProduct.photobookTemplate.coverAspectRatio, product.photobookTemplate.coverAspectRatio)
        XCTAssertEqual(photobookProduct.photobookTemplate.pageAspectRatio, product.photobookTemplate.pageAspectRatio)
        XCTAssertEqual(photobookProduct.photobookTemplate.layouts, product.photobookTemplate.layouts)
        XCTAssertEqual(photobookProduct.photobookTemplate.coverLayouts, product.photobookTemplate.coverLayouts)
        XCTAssertEqualOptional(photobookProduct.photobookTemplate.availableShippingMethods, product.photobookTemplate.availableShippingMethods)

        XCTAssertEqual(photobookProduct.coverColor, product.coverColor)
        XCTAssertEqual(photobookProduct.pageColor, product.pageColor)
        XCTAssertEqual(photobookProduct.identifier, product.identifier)
        XCTAssertEqual(photobookProduct.pigBaseUrl, product.pigBaseUrl)
        XCTAssertEqual(photobookProduct.pigCoverUrl, product.pigCoverUrl)
        XCTAssertEqual(photobookProduct.coverSnapshot, product.coverSnapshot)
        XCTAssertEqualOptional(photobookProduct.selectedShippingMethod?.id, product.selectedShippingMethod?.id)

        XCTAssertEqual(photobookProduct.productLayouts.first!.asset!.identifier, photosAsset.identifier)
        XCTAssertEqual(photobookProduct.productLayouts.first!.asset!.size, photosAsset.size)
    }

    func testFinishOrder_shouldFail_ifProductFailsToCreatePdfs() {
        
        // The photobook API fails to create PDFs
        photobookApiManager.error = .generic
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .uploadProcessing = error {
                return true
            }
            return false
        }

        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFinishOrder_shouldCancel_ifThereIsAnIssueWithTheOrderParameters() {
        
        // The photobook API creates PDFs but fails to build the parameters for submission
        order.orderParametersStub = nil
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .cancelled = error {
                return true
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFinishOrder_shouldCancel_ifOrderFailsWithAnUnrecoverableError() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Submitting the order fails
        kiteApiClient.submitError = APIClientError.parsing(details: "Well that went well")

        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .cancelled = error {
                return true
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }

    func testFinishOrder_shouldFail_ifOrderFailsWithServerError() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Submitting the order fails
        kiteApiClient.submitError = APIClientError.server(code: 10, message: "The server is off for the day")
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .api(let message) = error {
                return message.text == "The server is off for the day"
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }

    func testFinishOrder_shouldFail_ifOrderFailsWithAnyOtherApiError() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Submitting the order fails
        kiteApiClient.submitError = APIClientError.generic
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .api(let message) = error {
                return !message.text.isEmpty
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFinishOrder_shouldFail_ifPollingFailsWithPaymentError() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Order submits but polling fails
        kiteApiClient.orderId = "Order1"
        kiteApiClient.statusError = KiteAPIClientError.paymentError
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .payment = error {
                return true
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFinishOrder_shouldFail_ifPollingFailsWithAnyOtherApiError() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Order submits but polling fails
        kiteApiClient.orderId = "Order1"
        kiteApiClient.statusError = APIClientError.generic
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .api(let message) = error {
                return !message.text.isEmpty
            }
            return false
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFinishOrder_shouldSucceed() {
        
        // The photobook API creates PDFs
        photobookApiManager.pdfUrls = ["http://clown.co.uk/pdf1", "http://clown.co.uk/pdf2"]
        
        // Order submits but polling fails
        kiteApiClient.orderId = "Order1"
        kiteApiClient.status = .validated
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            return notification.object == nil
        }
        
        orderManager.finishOrder()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldCancel_ifTheAssetCannotBeRetrieved() {
        
        assetLoadingManager.fileExtension = .unsupported
        assetLoadingManager.error = AssetLoadingException.unsupported(details: "Something went very wrong")
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .cancelled = error {
                return true
            }
            return false
        }

        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldFail_ifTheAssetReturnsAnyOtherError() {
        
        assetLoadingManager.fileExtension = .unsupported
        assetLoadingManager.error = APIClientError.connection
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldFail_ifTheAssetUrlCannotBeRetrieved() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = nil // For clarity
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldFail_ifTheUploadReturnsNoInformation() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = nil // For clarity
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldFail_ifTheUploadReturnsAnApiError() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = ["error": APIClientError.connection]
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }

    func testUploadAssets_shouldFail_ifTheUploadDoesNotReturnAReference() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = ["full": "http://pig/223434.jpg"]
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }

    func testUploadAssets_shouldFail_ifTheUploadDoesNotReturnAUrl() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = ["task_reference": "\(apiClient.imageUploadIdentifierPrefix)\(photosAsset.identifier!)"]
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .upload = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }

    func testUploadAssets_shouldCancel_ifTheAssetCannotBeFoundInTheOrder() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = ["full": "http://pig/223434.jpg", "task_reference": "\(apiClient.imageUploadIdentifierPrefix)wrongID"]
        
        let expect = expectation(forNotification: .orderDidComplete, object: nil) { (notification) -> Bool in
            if let error = notification.object as? OrderProcessingError, case .cancelled = error {
                return true
            }
            return false
        }
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUploadAssets_shouldSucceed_updatingTheUrl() {
        
        assetLoadingManager.fileExtension = .jpg
        assetLoadingManager.imageData = Data()
        
        photobookApiManager.error = .generic
        
        orderDiskManager.fileUrl = URL(string: "http://clownrepo.co.uk/fiestaking.jpg")
        apiClient.uploadImageUserInfo = ["full": "http://pig/223434.jpg", "task_reference": "\(apiClient.imageUploadIdentifierPrefix)\(photosAsset.identifier!)"]
        
        let predicate = NSPredicate(format: "uploadUrl == %@", "http://pig/223434.jpg")
        let expect = expectation(for: predicate, evaluatedWith: photosAsset)
        
        orderManager.uploadAssets()
        
        wait(for: [expect], timeout: 5.0)
    }

}
