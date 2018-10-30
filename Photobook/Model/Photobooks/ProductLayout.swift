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

// A page in the user's photobook
class ProductLayout: Codable {
    var layout: Layout! {
        didSet {
            self.fitItemsInLayout(reset: oldValue.category != layout.category || !hasBeenEdited)
        }
    }
    var productLayoutAsset: ProductLayoutAsset?
    var productLayoutText: ProductLayoutText?
    var hasBeenEdited: Bool = false
    
    var asset: Asset? {
        get {
            return productLayoutAsset?.asset
        }
        set {
            guard layout.imageLayoutBox != nil || newValue == nil else {
                print("ProductLayout: Trying to assign asset to unavailable container")
                return
            }
            if productLayoutAsset == nil { productLayoutAsset = ProductLayoutAsset() }
            productLayoutAsset!.asset = newValue
        }
    }
    
    var text: String? {
        get {
            return productLayoutText?.text
        }
        set {
            guard layout.textLayoutBox != nil else {
                print("ProductLayout: Trying to assign text to unavailable container")
                return
            }
            if productLayoutText == nil { productLayoutText = ProductLayoutText() }
            productLayoutText!.text = newValue
        }
    }
        
    var fontType: FontType? {
        get {
            return productLayoutText?.fontType
        }
        set {
            guard layout.textLayoutBox != nil else {
                print("ProductLayout: Trying to assign a font type to unavailable container")
                return
            }
            guard newValue != nil else {
                print("ProductLayout: Trying to assign nil font type")
                return
            }
            if productLayoutText == nil { productLayoutText = ProductLayoutText() }
            productLayoutText!.fontType = newValue!
        }
    }
    
    var hasEmptyContent: Bool {
        return (layout.imageLayoutBox != nil && asset == nil) || (layout.imageLayoutBox == nil && layout.textLayoutBox != nil && (text ?? "").isEmpty)
    }
    
    init(layout: Layout, productLayoutAsset: ProductLayoutAsset? = nil, productLayoutText: ProductLayoutText? = nil) {
        self.layout = layout
        self.productLayoutAsset = productLayoutAsset
        self.productLayoutText = productLayoutText
    }
    
    enum CodingKeys: String, CodingKey {
        case layout, productLayoutAsset, productLayoutText
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layout, forKey: .layout)
        try container.encode(productLayoutAsset, forKey: .productLayoutAsset)
        try container.encode(productLayoutText, forKey: .productLayoutText)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        layout = try values.decode(Layout.self, forKey: .layout)
        productLayoutAsset = try values.decodeIfPresent(ProductLayoutAsset.self, forKey: .productLayoutAsset)
        productLayoutText = try values.decodeIfPresent(ProductLayoutText.self, forKey: .productLayoutText)
    }
    
    private func fitItemsInLayout(reset: Bool = true) {
        guard layout != nil else { return }
        
        if productLayoutAsset != nil && layout.imageLayoutBox != nil {
            productLayoutAsset!.shouldFitAsset = reset
            if reset {
                productLayoutAsset!.containerSize = layout.imageLayoutBox!.rect.size
            }
        }
    }
    
    func setText(_ text: String, withLineBreaks breaks: [Int]?) {
        self.text = text

        guard let breaks = breaks else {
            productLayoutText!.htmlText = text
            return
        }
        
        var text = text
        for line in (0 ..< breaks.count).reversed() {
            text.insert(contentsOf: "<br />", at: text.index(text.startIndex, offsetBy: breaks[line]))
        }
        productLayoutText!.htmlText = text
    }
    
    func shallowCopy() -> ProductLayout {
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset?.shallowCopy(), productLayoutText: productLayoutText?.deepCopy())
        productLayout.hasBeenEdited = hasBeenEdited
        return productLayout
    }
}

