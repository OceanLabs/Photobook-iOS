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
    
    override func get(context: APIContext, endpoint: String, parameters: [String : Any]?, headers: [String : String]? = nil, completion: @escaping (AnyObject?, Error?) -> ()) {
        completion(response, error)
    }
}


class PhotobookAPIManagerTests: XCTestCase {
    
    let apiClient = APIClientMock()
    lazy var photobookAPIManager = PhotobookAPIManager(apiClient: apiClient, mockJsonFileName: nil)
    
    override func tearDown() {
        apiClient.response = nil
        apiClient.error = nil
    }
    
    func testRequestPhotobookInfo_ReturnsServerError() {
        apiClient.error = APIClientError.server(code: 500, message: "")
        
        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: self.apiClient.error as! APIClientError), "PhotobookInfo: Should return a server error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsConnectionError() {
        apiClient.error = APIClientError.connection
        
        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .connection), "PhotobookInfo: Should return a server error")
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingError() {

        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingErrorWithNilObjects() {
    
        apiClient.response = [ "products": nil, "layouts": nil, "upsellOptions": nil ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithZeroCounts() {
        apiClient.response = [ "products": [], "layouts": [], "upsellOptions": [] ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithUnexpectedObjects() {
        
        apiClient.response = [ "products": 10, "layouts": "Not a layout" ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { (_, _, _, error) in
            XCTAssertTrue(APIClientError.isError(error, ofType: .parsing), "PhotobookInfo: Should return a parsing error")
        }
    }
    
    func testRequestPhotobookInfo_ShouldParseValidObjects() {
        apiClient.response = JSON.parse(file: "photobooks")
        
        photobookAPIManager.requestPhotobookInfo { (photobooks, layouts, upsellOptions, error) in
            XCTAssertNil(error, "PhotobookInfo: Error should be nil with a valid response")
            XCTAssertTrue((photobooks ?? []).count == 4, "PhotobookInfo: Photobooks should include layouts products")
            XCTAssertTrue((layouts ?? []).count == 54, "PhotobookInfo: Layouts should include 54 layouts")
            XCTAssertTrue((upsellOptions ?? []).count == 2, "PhotobookInfo: Layouts should include 2 upsell options")
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
