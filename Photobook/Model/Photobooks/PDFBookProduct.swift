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

class PDFBookTemplate: Codable, Template {
    var templateId: String
    var name: String
    var availableShippingMethods: [String: [ShippingMethod]]?
    var countryToRegionMapping: [String: [String]]?
    
    init(templateId: String) {
        self.templateId = templateId
        name = "Custom PDF Book"
    }
}

@objc public class PDFBookProduct: NSObject, Codable, Product {
    
    private static let productThumbnailUrlString = "https://s3.amazonaws.com/sdk-static/product_photography/hd_photobooks/detail.1.jpg"
    
    var pdfBookTemplate: PDFBookTemplate
    var coverPdfAsset: PDFAsset
    var insidePdfAsset: PDFAsset
    var options: [String: Any]?
    
    private var pageCount: Int
    
    public var itemCount: Int = 1
    public var selectedShippingMethod: ShippingMethod?
    public private(set) var identifier = UUID().uuidString
    public var template: Template { return pdfBookTemplate }
    
    public init?(templateId: String, coverFilePath: String, insideFilePath: String, pageCount: Int, options: [String: Any]? = nil) {
        guard let coverPdfAsset = PDFAsset(filePath: coverFilePath),
              let insidePdfAsset = PDFAsset(filePath: insideFilePath)
            else {
                return nil
        }
        self.pdfBookTemplate = PDFBookTemplate(templateId: templateId)
        self.coverPdfAsset = coverPdfAsset
        self.insidePdfAsset = insidePdfAsset
        self.pageCount = pageCount
        self.options = options
    }
    
    public func assetsToUpload() -> [PhotobookAsset]? {
        return [PhotobookAsset(asset: coverPdfAsset)!, PhotobookAsset(asset: insidePdfAsset)!]
    }
    
    public func costParameters() -> [String: Any]? {
        guard let shippingMethod = selectedShippingMethod else { return nil }
        var parameters: [String: Any] = [
            "template_id": template.templateId,
            "multiples": itemCount,
            "shipping_class": shippingMethod.id,
            "page_count": pageCount,
            "job_id": identifier
        ]
        if let options = options { parameters["options"] = options }
        return parameters
    }
    
    public func orderParameters() -> [String: Any]? {
        guard let insideUrl = coverPdfAsset.uploadUrl,
              let coverUrl = insidePdfAsset.uploadUrl,
              let shippingMethod = selectedShippingMethod
        else {
                return nil
        }
        
        var parameters: [String: Any] = [
            "template_id": template.templateId,
            "multiples": itemCount,
            "shipping_class": shippingMethod.id,
            "page_count": pageCount,
            "inside_pdf": insideUrl,
            "cover_pdf": coverUrl
        ]
        if let options = options { parameters["options"] = options }
        return parameters
    }
    
    public func previewImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void) {
        let url = URL(string: PDFBookProduct.productThumbnailUrlString)!
        guard let data = try? Data(contentsOf: url) else {
            completionHandler(nil)
            return
        }
        let image = UIImage(data: data, scale: 1.0)
        completionHandler(image)
    }
    
    public func processUploadedAssets(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
    
    private enum CodingKeys: String, CodingKey {
        case pdfBookTemplate, coverPdfAsset, insidePdfAsset, pageCount, itemCount, selectedShippingMethod, identifier
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pdfBookTemplate, forKey: .pdfBookTemplate)
        try container.encode(coverPdfAsset, forKey: .coverPdfAsset)
        try container.encode(insidePdfAsset, forKey: .insidePdfAsset)
        try container.encode(pageCount, forKey: .pageCount)
        try container.encode(itemCount, forKey: .itemCount)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(selectedShippingMethod, forKey: .selectedShippingMethod)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pdfBookTemplate = try values.decode(PDFBookTemplate.self, forKey: .pdfBookTemplate)
        coverPdfAsset = try values.decode(PDFAsset.self, forKey: .coverPdfAsset)
        insidePdfAsset = try values.decode(PDFAsset.self, forKey: .insidePdfAsset)
        pageCount = try values.decode(Int.self, forKey: .pageCount)
        itemCount = try values.decode(Int.self, forKey: .itemCount)
        selectedShippingMethod = try values.decodeIfPresent(ShippingMethod.self, forKey: .selectedShippingMethod)
        identifier = try values.decode(String.self, forKey: .identifier)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let data = try? PropertyListEncoder().encode(self) {
            aCoder.encode(data, forKey: "productData")
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: "productData") as? Data,
              let unarchived = try? PropertyListDecoder().decode(PDFBookProduct.self, from: data)
            else {
                return nil
        }
        
        pdfBookTemplate = unarchived.pdfBookTemplate
        coverPdfAsset = unarchived.coverPdfAsset
        insidePdfAsset = unarchived.insidePdfAsset
        pageCount = unarchived.pageCount
        itemCount = unarchived.itemCount
        identifier = unarchived.identifier
        selectedShippingMethod = unarchived.selectedShippingMethod
    }
}
