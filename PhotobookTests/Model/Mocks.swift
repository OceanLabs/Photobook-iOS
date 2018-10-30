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

class APIClientMock: APIClient {
    
    var response: AnyObject?
    var image: UIImage?
    var error: APIClientError?
    var uploadImageUserInfo: [String: Any]?
    
    override func get(context: APIContext, endpoint: String, parameters: [String : Any]?, headers: [String : String]? = nil, completion: @escaping (AnyObject?, APIClientError?) -> ()) {
        completion(response, error)
    }
    
    override func post(context: APIContext, endpoint: String, parameters: [String : Any]?, headers: [String : String]?, completion: @escaping (AnyObject?, APIClientError?) -> ()) {
        completion(response, error)
    }
    
    override func uploadImage(_ image: UIImage, imageName: String, completion: @escaping (AnyObject?, Error?) -> ()) {
        completion(response, error)
    }
    
    override func uploadImage(_ file: URL, reference: String?) {
        NotificationCenter.default.post(name: APIClient.backgroundSessionTaskFinished, object: nil, userInfo: uploadImageUserInfo)
    }
    
    override func downloadImage(_ imageUrl: URL, completion: @escaping (UIImage?, Error?) -> ()) {
        completion(image, error)
    }
}

class KiteAPIClientMock: KiteAPIClient {
    
    var orderId: String?
    var submitError: APIClientError?
    
    var status: OrderSubmitStatus?
    var receipt: String?
    var statusError: APIClientError?
    
    override func submitOrder(parameters: [String: Any], completionHandler: @escaping (_ orderId: String?, _ error: APIClientError?) -> Void) {
        completionHandler(orderId, submitError)
    }
    
    override func checkOrderStatus(receipt: String, completionHandler: @escaping (_ status: OrderSubmitStatus, _ error: APIClientError?, _ receipt: String?) -> Void) {
        completionHandler(status!, statusError, receipt)
    }
}

class PhotobookAPIManagerMock: PhotobookAPIManager {
    
    var pdfUrls: [String]?
    var error: Error?
    
    override func createPdf(withPhotobook photobook: PhotobookProduct, completionHandler: @escaping ([String]?, Error?) -> Void) {
        completionHandler(pdfUrls, error)
    }    
}

class OrderDiskManagerMock: OrderDiskManager {
    var fileUrl: URL?
    
    func saveDataToCachesDirectory(data: Data, name: String) -> URL? {
        return fileUrl
    }
}
