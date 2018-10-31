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
@testable import Photobook

class OrderSummaryManagerTests: XCTestCase {

    let apiClient = APIClientMock()
    lazy var photobookApiManager = PhotobookAPIManager(apiClient: apiClient)
    var orderSummaryManager: OrderSummaryManager!
    var delegate: OrderSummaryManagerDelegateMock!
    
    var validSummaryResponse = ["summary": [
        "lineItems": [["name": "item1", "price": ["amount": 2.00, "currencyCode": "GBP"]],
                      ["name": "item2", "price": ["amount": 3.00, "currencyCode": "GBP"]]],
        "total": ["amount": 5.0, "currencyCode": "GBP"],
        "previewImageUrl": "http://pig/image.png"
        ],
                        "upsells": [["type": "size", "displayName": "Larger book"],
                                    ["type": "finish", "displayName": "Gloss"]],
                        "productPayload": ["options": ["size": "Huge book"]]
    ] as [String: AnyObject]
    
    lazy var templates: [PhotobookTemplate]! = {
        apiClient.response = JSON.parse(file: "photobooks")
        let productManager = ProductManager(apiManager: photobookApiManager)
        productManager.initialise(completion: nil)
        
        product = productManager.setCurrentProduct(with: productManager.products!.first!, assets: [])

        return productManager.products
    }()
    var product: PhotobookProduct!
    
    override func setUp() {
        Pig.apiClient = apiClient
        
        delegate = OrderSummaryManagerDelegateMock()
        
        orderSummaryManager = OrderSummaryManager()
        orderSummaryManager.apiManager = photobookApiManager
        orderSummaryManager.apiClient = apiClient
        orderSummaryManager.templates = templates
        orderSummaryManager.product = product
        orderSummaryManager.delegate = delegate
        
        if product == nil {
            XCTFail("Could not initialise product")
            return
        }
    }
    
    override func tearDown() {
        apiClient.response = nil
    }
    
    func upsellResponse(templateId: String = "madeUpId") -> [String: AnyObject] {
        return ["summary":
                    ["lineItems": [["name": "item1", "price": ["amount": 2.00, "currencyCode": "GBP"]]],
                     "total": ["amount": 5.0, "currencyCode": "GBP"],
                     "previewImageUrl": "http://pig/image.png"
                        ],
                    "newProduct": ["variants": [["templateId": templateId]]],
                    "productPayload": ["options": []]
                ] as [String: AnyObject]
    }
    
    func testRefresh_shouldNotifyDelegateIfSummaryIsMissing() {
        var missingSummaryResponse = validSummaryResponse
        missingSummaryResponse["summary"] = nil
    
        orderSummaryManager.getSummary()
        XCTAssertNotNil(delegate.error)
    }
    
    func testRefresh_shouldFetchSummaryAndUpsells() {
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()
        
        // Populated the upsells
        XCTAssertEqualOptional(orderSummaryManager.upsellOptions?.count, 2)
        // Populated the summary
        XCTAssertNotNil(orderSummaryManager.summary)
        XCTAssertNotNil(product.upsoldOptions)
        // Notified delegate with summary
        XCTAssertNotNil(delegate.summary)
    }
    
    func testSelectUpsellOption_shouldSucceedWithValidResponse() {
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()
        
        guard let firstUpsellOption = orderSummaryManager.upsellOptions?.first else {
            XCTFail("Could not parse upsells")
            return
        }
        
        apiClient.response = upsellResponse(templateId: templates[1].templateId) as AnyObject
        orderSummaryManager.selectUpsellOption(firstUpsellOption)
        
        // First option should be selected
        XCTAssertEqual(orderSummaryManager.selectedUpsellOptions.first, firstUpsellOption)
        // Should update the upsold template
        XCTAssertEqualOptional(product.upsoldTemplate?.templateId, templates[1].templateId)
    }

    func testSelectUpsellOption_shouldFailIfUpsoldTemplateIsNotInTheList() {
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()
        
        guard let firstUpsellOption = orderSummaryManager.upsellOptions?.first else {
            XCTFail("Could not parse upsells")
            return
        }
        
        apiClient.response = upsellResponse() as AnyObject
        orderSummaryManager.selectUpsellOption(firstUpsellOption)
        
        // Does not select the upsell
        XCTAssertEqual(orderSummaryManager.selectedUpsellOptions.count, 0)
        
        // Raises an error
        XCTAssertNotNil(delegate.error)
    }

    func testDeselectUpsellOption_shouldSucceedWithValidResponse() {
        testSelectUpsellOption_shouldSucceedWithValidResponse()
        
        let firstUpsellOption = orderSummaryManager.upsellOptions!.first!

        apiClient.response = upsellResponse(templateId: templates.first!.templateId) as AnyObject
        orderSummaryManager.deselectUpsellOption(firstUpsellOption)
        
        // There should be no selected options
        XCTAssertEqual(orderSummaryManager.selectedUpsellOptions.count, 0)
     
        // Template ID should match response
        XCTAssertEqualOptional(product.upsoldTemplate?.templateId, templates.first!.templateId)
    }
    
    func testDeselectUpsellOption_shouldFailIfUpsoldTemplateIsNotInTheList() {
        testSelectUpsellOption_shouldSucceedWithValidResponse()
        
        let firstUpsellOption = orderSummaryManager.upsellOptions!.first!
        
        apiClient.response = upsellResponse as AnyObject
        orderSummaryManager.deselectUpsellOption(firstUpsellOption)
        
        // The option should remain selected
        XCTAssertEqual(orderSummaryManager.selectedUpsellOptions.first, firstUpsellOption)
        
        // Raises an error
        XCTAssertNotNil(delegate.error)
    }
    
    func testUploadCoverImage_shouldFailWithoutACoverImage() {
        orderSummaryManager.coverPageSnapshotImage = nil
        
        XCTAssertTrue(delegate.calledFailedToSetPreviewImageUrl)
    }
    
    func testUploadCoverImage_shouldFailIfApiReturnsError() {
        apiClient.error = .generic
        
        orderSummaryManager.coverPageSnapshotImage = UIImage()
        
        XCTAssertTrue(delegate.calledFailedToSetPreviewImageUrl)        
    }
    
    func testUploadCoverImage_shouldFailIfApiResponseIsInvalid() {
        apiClient.response = ["message": "image uploaded"] as AnyObject
        
        orderSummaryManager.coverPageSnapshotImage = UIImage()
        
        XCTAssertTrue(delegate.calledFailedToSetPreviewImageUrl)
    }
    
    func testUploadCoverImage_shouldNotifyDelegateIfImageUrlIsReady() {
        // Request summary and product preview URL
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()

        // Simulate cover upload
        apiClient.response = ["full": "http://cover.url/"] as AnyObject
        orderSummaryManager.coverPageSnapshotImage = UIImage()
        
        // Should notify delegate that URL is ready
        XCTAssertTrue(delegate.calledDidSetPreviewImageUrl)
    }
    
    func testFetchPreviewImage_shouldCallCompletionWhenCoverImageIsNotPresent() {
        orderSummaryManager.fetchPreviewImage(withSize: .zero) { (image) in
            XCTAssertNil(image)
        }
    }
    
    func testFetchPreviewImage_shouldCallCompletionIfDownloadFails() {
        // Request summary and product preview URL
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()
        
        // Simulate cover upload
        apiClient.response = ["full": "http://cover.url/"] as AnyObject
        orderSummaryManager.coverPageSnapshotImage = UIImage()

        apiClient.error = .generic
        
        orderSummaryManager.fetchPreviewImage(withSize: .zero) { (image) in
            XCTAssertNil(image)
        }
    }
    
    func testFetchPreviewImage_shouldCallCompletionWithImageForASuccessfulDownload() {
        // Request summary and product preview URL
        apiClient.response = validSummaryResponse as AnyObject
        orderSummaryManager.getSummary()
        
        // Simulate cover upload
        apiClient.response = ["full": "http://cover.url/"] as AnyObject
        orderSummaryManager.coverPageSnapshotImage = UIImage()
        
        apiClient.image = UIImage()
    
        orderSummaryManager.fetchPreviewImage(withSize: .zero) { (image) in
            XCTAssertNotNil(image)
        }

    }
}
