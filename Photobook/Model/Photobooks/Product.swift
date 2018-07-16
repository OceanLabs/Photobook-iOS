//
//  Product.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 10/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

@objc public protocol Product: NSCoding {
    var selectedShippingMethod: ShippingMethod? { get set }
    var identifier: String { get }
    var itemCount: Int { get set }
    var template: Template { get }
    var upsoldTemplate: Template? { get }
    var upsoldOptions: [String: Any]? { get }
    var numberOfPages: Int { get }
    var hashValue: Int { get }
    func assetsToUpload() -> [PhotobookAsset]?
    func orderParameters() -> [String: Any]?
    func previewImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void)
    func processUploadedAssets(completionHandler: @escaping (Error?) -> Void)
}
