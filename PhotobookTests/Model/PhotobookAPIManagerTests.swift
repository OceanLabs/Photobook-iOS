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
        let product = [ "id": 10,
          "name": "210 x 210",
          "pageWidth": 1000,
          "pageHeight": 400,
          "coverWidth": 1030,
          "coverHeight": 415,
          "cost": [ "EUR": Decimal(10.00), "USD": Decimal(12.00), "GBP": Decimal(9.00) ] as [String: Decimal],
          "costPerPage": [ "EUR": Decimal(1.00), "USD": Decimal(1.20), "GBP": Decimal(0.85) ] as [String: Decimal],
          "coverLayouts": [ 10 ],
          "layouts": [ 10 ]
        ] as [String: AnyObject]
        
        let layout =
            [ "id": 10,
              "category": "squareCentred",
              "imageUrl": "/images/10.png",
              "imageLayoutBox": [
                "id": 1,
                "rect": [ "x": 0.0, "y": 0.01, "width": 0.1, "height": 0.1 ]
               ],
              "textLayoutBox": [
                "id": 2,
                "rect" : [ "x": 0.0, "y": 0.01, "width": 0.1, "height": 0.1 ]
                ]
            ] as [String: AnyObject]
        
        apiClient.response = [ "products": [ product ], "layouts": [ layout ]] as AnyObject
        
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
