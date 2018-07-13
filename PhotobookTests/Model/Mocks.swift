//
//  Mocks.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 12/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
    
    override func uploadImage(_ image: UIImage, imageName: String, context: APIContext, endpoint: String, completion: @escaping (AnyObject?, Error?) -> ()) {
        completion(response, error)
    }
    
    override func uploadImage(_ file: URL, reference: String?, context: APIContext, endpoint: String) {
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
