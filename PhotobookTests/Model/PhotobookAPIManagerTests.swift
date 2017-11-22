//
//  PhotobookAPIManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class APIClientMock: APIClient {
    
    var response: AnyObject?
    var error: Error?
    
    override func get(context: APIContext, endpoint: String, parameters: [String : Any]?, completion: @escaping (AnyObject?, Error?) -> ()) {
        completion(response, error)
    }
}


class PhotobookAPIManagerTests: XCTestCase {
    
    let apiClient = APIClientMock()
    lazy var photobookAPIManager = PhotobookAPIManager(apiClient: apiClient)
    
    override func tearDown() {
        apiClient.response = nil
        apiClient.error = nil
    }
    
    func testRequestPhotobookInfo_ReturnsServerError() {
        apiClient.error = APIClientError.server(code: 500, message: "")
        
        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: self.apiClient.error as! APIClientError), "PhotobookInfo: Should return a server error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsConnectionError() {
        apiClient.error = APIClientError.connection
        
        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .connection), "PhotobookInfo: Should return a server error")
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingError() {

        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingErrorWithNilObjects() {
    
        apiClient.response = [ "products": nil, "layouts": nil ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithZeroCounts() {
        apiClient.response = [ "products": [], "layouts": [] ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithUnexpectedObjects() {
        
        apiClient.response = [ "products": 10, "layouts": "Not a layout" ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ShouldParseValidObjects() {
        let products = [
            [ "id": 10 as AnyObject,
              "name": "210 x 210" as AnyObject,
              "pageWidth": 1000 as AnyObject,
              "pageHeight": 400 as AnyObject,
              "coverWidth": 1030 as AnyObject,
              "coverHeight": 415 as AnyObject,
              "cost": [ "EUR": Decimal(10.00), "USD": Decimal(12.00), "GBP": Decimal(9.00) ] as AnyObject,
              "costPerPage": [ "EUR": Decimal(1.00), "USD": Decimal(1.20), "GBP": Decimal(0.85) ] as AnyObject,
              "layouts": [ 10 ]
              ]
        ]
        
        let layouts = [
            [ "id": 10, "name": "layout10", "imageUrl": "/images/10.png",
              "layoutBoxes": [
                    [ "contentType": "image", "dimensionsPercentages": [ "width": 0.1, "height": 0.1 ], "relativeStartPoint": [ "x": 0.0, "y": 0.01 ] ]
                ]
            ]
        ]
        
        apiClient.response = [ "products": products, "layouts": layouts] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (photobooks, layouts, error) in
            XCTAssertNil(error, "PhotobookInfo: Error should be nil with a valid response")
            XCTAssertTrue((photobooks ?? []).count == 1, "PhotobookInfo: Photobooks should include one product")
            XCTAssertTrue((layouts ?? []).count == 1, "PhotobookInfo: Photobooks should include one product")
        }
    }
}

extension APIClientError {
    
    static func isError(_ error: Error?, ofType: APIClientError) -> Bool {
        guard let error = error as? APIClientError else { return false }
        
        switch (error, ofType) {
        case let (.server(codeA, _), .server(codeB, _)):
            if codeA == codeB { return true }
        case (.parsing, .parsing):
            fallthrough
        case (.connection, .connection):
            return true
        default:
            break
        }
        return false
    }
}
