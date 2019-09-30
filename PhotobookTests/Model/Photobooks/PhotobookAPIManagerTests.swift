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

class PhotobookAPIManagerTests: XCTestCase {
    
    let apiClient = APIClientMock()
    lazy var photobookAPIManager = PhotobookAPIManager(apiClient: apiClient)
    
    override func tearDown() {
        apiClient.response = nil
        apiClient.error = nil
    }
    
    func testRequestPhotobookInfo_ReturnsServerError() {
        apiClient.error = .server(code: 500, message: "")
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: self.apiClient.error!), "PhotobookInfo: Should return a server error")
                return
            }
            XCTFail()
        }
    }
    
    func testRequestPhotobookInfo_ReturnsConnectionError() {
        apiClient.error = .connection
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: .connection), "PhotobookInfo: Should return a server error")
                return
            }
            XCTFail()
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingError() {
        apiClient.error = .parsing(details: "Something went wrong")
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: .parsing(details: "")), "PhotobookInfo: Should return a parsing error")
                return
            }
            XCTFail()
        }
    }

    func testRequestPhotobookInfo_ReturnsParsingErrorWithNilObjects() {
    
        apiClient.response = [ "products": nil, "layouts": nil, "upsellOptions": nil ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: .parsing(details: "")), "PhotobookInfo: Should return a parsing error")
                return
            }
            XCTFail()
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithZeroCounts() {
        apiClient.response = [ "products": [], "layouts": [], "upsellOptions": [] ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: .parsing(details: "")), "PhotobookInfo: Should return a parsing error")
                return
            }
            XCTFail()
        }
    }
    
    func testRequestPhotobookInfo_ReturnsParsingErrorWithUnexpectedObjects() {
        
        apiClient.response = [ "products": 10, "layouts": "Not a layout" ] as AnyObject
        
        photobookAPIManager.requestPhotobookInfo { result in
            if case .failure(let error) = result {
                XCTAssertTrue(APIClientError.isError(error, ofType: .parsing(details: "")), "PhotobookInfo: Should return a parsing error")
                return
            }
            XCTFail()
        }
    }
    
    func testRequestPhotobookInfo_ShouldParseValidObjects() {
        apiClient.response = JSON.parse(file: "photobooks")
        
        photobookAPIManager.requestPhotobookInfo { result in
            switch result {
            case .failure(let error):
                XCTAssertNil(error, "PhotobookInfo: Error should be nil with a valid response")
            case .success(let (photobooks, layouts)):
                XCTAssertEqual(photobooks.count, 4, "PhotobookInfo: Photobooks should include layouts products")
                XCTAssertEqual(layouts.count, 52, "PhotobookInfo: Layouts should include 52 layouts")
            }
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
