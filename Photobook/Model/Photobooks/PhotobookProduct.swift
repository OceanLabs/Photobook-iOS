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

enum ProductColor: String, Codable {
    case white, black
    
    func fontColor() -> UIColor {
        switch self {
        case .white: return .black
        case .black: return .white
        }
    }
    
    func uiColor() -> UIColor {
        switch self {
        case .white: return .white
        case .black: return .black
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .white: return NSLocalizedString("Accessibility/Editing/WhiteColor", value: "White Color", comment: "The color white")
        case .black: return NSLocalizedString("Accessibility/Editing/BlackColor", value: "Black Color", comment: "The color black")
        }
    }
}

@objc class PhotobookProduct: NSObject, Codable, Product {

    private enum CodingKeys: String, CodingKey {
        case photobookTemplate, productLayouts, coverColor, pageColor, spineText, spineFontType, productUpsellOptions, itemCount, photobookUpsoldTemplate, upsoldOptions, availableShippingMethods, selectedShippingMethod, identifier, pigBaseUrl, pigCoverUrl, coverSnapshot
    }
    
    private var currentPortraitLayout = 0
    private var currentLandscapeLayout = 0
    
    var photobookTemplate: PhotobookTemplate
    var productUpsellOptions: [UpsellOption]?
    var spineText: String?
    var spineFontType: FontType = .plain
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    var itemCount: Int = 1
    var insidePdfUrl: String?
    var coverPdfUrl: String?
    private(set) var identifier = UUID().uuidString
    var selectedShippingMethod: ShippingMethod?
    
    // Preview image handling
    var pigBaseUrl: String?
    var pigCoverUrl: String?
    var coverSnapshot: UIImage?
    
    var isAddingPagesAllowed: Bool { return photobookTemplate.maxPages >= numberOfPages + 2 }
    var isRemovingPagesAllowed: Bool { return numberOfPages - 2 >= photobookTemplate.minPages }
    
    var numberOfPages: Int {
        let doubleLayouts = productLayouts.filter { $0.layout.isDoubleLayout }.count
        let singleLayouts = productLayouts.count - doubleLayouts - 1 // Don't count the cover
        return singleLayouts + 2 * doubleLayouts
    }
    
    var coverLayouts: [Layout]!
    var layouts: [Layout]!

    private(set) var photobookUpsoldTemplate: PhotobookTemplate?
    private(set) var upsoldOptions: [String: Any]?
    
    var template: Template { return photobookTemplate }
    var upsoldTemplate: Template? { return photobookUpsoldTemplate }
    
    func setUpsellData(template: PhotobookTemplate?, payload: [String: Any]?) {
        photobookUpsoldTemplate = template
        upsoldOptions = payload?["options"] as? [String: Any]
    }
    
    var emptyLayoutIndices: [Int]? {
        var temp = [Int]()
        var index = 0
        for productLayout in productLayouts {
            if productLayout.hasEmptyContent {
                temp.append(index)
                if productLayout.layout.isDoubleLayout {
                    index += 1
                    temp.append(index)
                }
            }
            index += 1
        }
        return temp.count > 0 ? temp : nil
    }
    
    var truncatedTextLayoutIndices: [Int]? {
        var temp = [Int]()
                
        for (index, productLayout) in productLayouts.enumerated() {
            guard let textBox = productLayout.layout.textLayoutBox, let text = productLayout.text, text.count > 0 else { continue }
            
            let pageSize = index == 0 ? photobookTemplate.coverSize : photobookTemplate.pageSize
            
            let fontType = productLayout.fontType ?? .plain
            let fontSize = fontType.sizeForScreenToPageRatio()
            
            let textFrame = textBox.rectContained(in: pageSize)
            let attributedText = fontType.attributedText(with: text, fontSize: fontSize, fontColor: .black)
            
            let textHeight = attributedText.height(for: textFrame.width)
            if textHeight > textFrame.height {
                temp.append(index)
            }
        }
        return temp.count > 0 ? temp : nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(photobookTemplate, forKey: .photobookTemplate)
        try container.encode(productLayouts, forKey: .productLayouts)
        try container.encode(coverColor, forKey: .coverColor)
        try container.encode(pageColor, forKey: .pageColor)
        try container.encode(spineText, forKey: .spineText)
        try container.encode(spineFontType, forKey: .spineFontType)
        try container.encode(productUpsellOptions, forKey: .productUpsellOptions)
        try container.encode(itemCount, forKey: .itemCount)
        try container.encode(photobookUpsoldTemplate, forKey: .photobookUpsoldTemplate)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(selectedShippingMethod, forKey: .selectedShippingMethod)
        try container.encode(pigBaseUrl, forKey: .pigBaseUrl)
        try container.encode(pigCoverUrl, forKey: .pigCoverUrl)
        if let coverSnapshot = coverSnapshot {
            try container.encode(coverSnapshot.pngData(), forKey: .coverSnapshot)
        }
        if let upsoldOptions = upsoldOptions,
            let upsoldOptionData = try? JSONSerialization.data(withJSONObject: upsoldOptions, options: []) {
            try container.encode(upsoldOptionData, forKey: .upsoldOptions)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        photobookTemplate = try values.decode(PhotobookTemplate.self, forKey: .photobookTemplate)
        productLayouts = try values.decode([ProductLayout].self, forKey: .productLayouts)
        coverColor = try values.decode(ProductColor.self, forKey: .coverColor)
        pageColor = try values.decode(ProductColor.self, forKey: .pageColor)
        spineText = try values.decodeIfPresent(String.self, forKey: .spineText)
        spineFontType = try values.decode(FontType.self, forKey: .spineFontType)
        productUpsellOptions = try values.decodeIfPresent([UpsellOption].self, forKey: .productUpsellOptions)
        itemCount = try values.decode(Int.self, forKey: .itemCount)
        photobookUpsoldTemplate = try values.decodeIfPresent(PhotobookTemplate.self, forKey: .photobookUpsoldTemplate)
        identifier = try values.decode(String.self, forKey: .identifier)
        selectedShippingMethod = try values.decodeIfPresent(ShippingMethod.self, forKey: .selectedShippingMethod)
        pigBaseUrl = try values.decodeIfPresent(String.self, forKey: .pigBaseUrl)
        pigCoverUrl = try values.decodeIfPresent(String.self, forKey: .pigCoverUrl)
        if let coverSnapshotData = try values.decodeIfPresent(Data.self, forKey: .coverSnapshot) {
            coverSnapshot = UIImage(data: coverSnapshotData)
        }
        if let upsoldOptionsData = try values.decodeIfPresent(Data.self, forKey: .upsoldOptions) {
            upsoldOptions = (try? JSONSerialization.jsonObject(with: upsoldOptionsData, options: [])) as? [String: Any]
        }
    }
    
    func encode(with aCoder: NSCoder) {
        if let data = try? PropertyListEncoder().encode(self) {
            aCoder.encode(data, forKey: "productData")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        guard let data = aDecoder.decodeObject(forKey: "productData") as? Data,
            let unarchived = try? PropertyListDecoder().decode(PhotobookProduct.self, from: data)
            else {
                return nil
        }
        
        photobookTemplate = unarchived.photobookTemplate
        productLayouts = unarchived.productLayouts
        coverColor = unarchived.coverColor
        pageColor = unarchived.pageColor
        spineText = unarchived.spineText
        spineFontType = unarchived.spineFontType
        productUpsellOptions = unarchived.productUpsellOptions
        itemCount = unarchived.itemCount
        photobookUpsoldTemplate = unarchived.photobookUpsoldTemplate
        identifier = unarchived.identifier
        selectedShippingMethod = unarchived.selectedShippingMethod
        pigBaseUrl = unarchived.pigBaseUrl
        pigCoverUrl = unarchived.pigCoverUrl
        coverSnapshot = unarchived.coverSnapshot
        upsoldOptions = unarchived.upsoldOptions
        
    }
    
    init?(template: PhotobookTemplate, assets: [Asset], coverLayouts: [Layout], layouts: [Layout]) {
        guard !coverLayouts.isEmpty, !layouts.isEmpty else {
            print("PhotobookProduct: Missing layouts for selected photobook")
            return nil
        }
        
        self.photobookTemplate = template
        
        let countryCode = Country.countryForCurrentLocale().codeAlpha3
        self.selectedShippingMethod = template.availableShippingMethods?[countryCode]?.first
        self.coverLayouts = coverLayouts
        self.layouts = layouts
        
        let imageOnlyLayouts = layouts.filter({ $0.imageLayoutBox != nil })
        
        var assets = assets
        var tempLayouts = [ProductLayout]()
        
        // TEMP: Use the first asset and remove it if the number of assets matches the number of required pages + cover.
        //       Otherwise, pick one photo at random.
        var coverAsset: Asset?
        if assets.count % 2 != 0 {
            coverAsset = assets.remove(at: 0)
        } else {
            // Use a random photo for the cover, but not the first
            coverAsset = assets.first
            if assets.count > 1 {
                coverAsset = assets[Int.random(in: 1 ..< assets.count)] // Exclude 0
            }
        }
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = coverAsset
        let coverLayout = coverLayouts.first(where: { $0.imageLayoutBox != nil } )
        let productLayout = ProductLayout(layout: coverLayout!, productLayoutAsset: productLayoutAsset)
        tempLayouts.append(productLayout)
        
        // Create layouts for the remaining assets
        // Fill minimum pages with Placeholder assets if needed
        let numberOfPlaceholderLayoutsNeeded = max(template.minPages - assets.count, 0)
        super.init()
        tempLayouts.append(contentsOf: createLayoutsForAssets(assets: assets, from: imageOnlyLayouts, placeholderLayouts: numberOfPlaceholderLayoutsNeeded))
        productLayouts = tempLayouts
    }
    
    func setTemplate(_ template: PhotobookTemplate, coverLayouts: [Layout], layouts: [Layout]) {
        guard !coverLayouts.isEmpty, !layouts.isEmpty else {
            print("PhotobookProduct: Missing layouts for selected photobook")
            return
        }

        // Reset the current layout since we are changing products
        currentLandscapeLayout = 0
        currentPortraitLayout = 0
        
        // Switching products
        self.photobookTemplate = template
        self.coverLayouts = coverLayouts
        self.layouts = layouts
        
        for pageLayout in productLayouts {
            let availableLayouts = pageLayout === productLayouts.first ? coverLayouts : layouts
            
            // Match layouts from the current product to the new one
            var newLayout = availableLayouts.first {
                $0.category == pageLayout.layout.category
            }
            if newLayout == nil {
                // Should not happen but to be safe, pick the first layout
                newLayout = availableLayouts.first
            }
            pageLayout.layout = newLayout
        }
    }
    
    private func createLayoutsForAssets(assets: [Asset], from layouts: [Layout], placeholderLayouts: Int = 0) -> [ProductLayout] {
        var portraitLayouts = layouts.filter { !$0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
        var landscapeLayouts = layouts.filter { $0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
        let doubleLayout = layouts.first { $0.isDoubleLayout }
    
        var productLayouts = [ProductLayout]()
        
        func nextLandscapeLayout() -> Layout {
            defer { currentLandscapeLayout = currentLandscapeLayout < landscapeLayouts.count - 1 ? currentLandscapeLayout + 1 : 0 }
            return landscapeLayouts[currentLandscapeLayout]
        }

        func nextPortraitLayout() -> Layout {
            defer { currentPortraitLayout = currentPortraitLayout < portraitLayouts.count - 1 ? currentPortraitLayout + 1 : 0 }
            return portraitLayouts[currentPortraitLayout]
        }

        // If assets count is an odd number, use a double layout close to the middle of the photobook
        var doubleAssetIndex: Int?
        if doubleLayout != nil, placeholderLayouts == 0 && assets.count % 2 != 0 {
            var middleIndex = assets.count / 2
            if middleIndex % 2 == 0 { middleIndex -= 1 } // Always start with an odd number (left page)
            for i in stride(from: 0, to: middleIndex-1, by: 2) { // Exclude first and last assets
                if assets[middleIndex - i].isLandscape {
                    doubleAssetIndex = middleIndex - i
                    break
                }
                if assets[middleIndex + i].isLandscape {
                    doubleAssetIndex = middleIndex + i
                    break
                }
            }
            doubleAssetIndex = doubleAssetIndex ?? middleIndex // Use middle index even though it is a portrait photo
        }
        
        for (index, asset) in assets.enumerated() {
            let productLayoutAsset = ProductLayoutAsset()
            productLayoutAsset.asset = asset
            
            let layout: Layout
            if let doubleAssetIndex = doubleAssetIndex, index == doubleAssetIndex {
                layout = doubleLayout!
            } else if asset.isLandscape {
                layout = nextLandscapeLayout()
            } else {
                layout = nextPortraitLayout()
            }
            let productLayoutText = layout.textLayoutBox != nil ? ProductLayoutText() : nil
            let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: productLayoutText)
            productLayouts.append(productLayout)
        }
        
        var placeholderLayouts = placeholderLayouts
        while placeholderLayouts > 0 {
            let layout = placeholderLayouts % 2 == 0 ? nextLandscapeLayout() : nextPortraitLayout()
            let productLayout = ProductLayout(layout: layout, productLayoutAsset: nil)
            productLayouts.append(productLayout)
            placeholderLayouts -= 1
        }
        
        return productLayouts
    }
    
    /// Sets one of the available layouts for a page number
    ///
    /// - Parameters:
    ///   - layout: The layout to use
    ///   - page: The page index in the photobook
    func setLayout(_ layout: Layout, forPage page: Int) {
        productLayouts[page].layout = layout
    }
    
    /// Sets an asset as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - asset: The image asset to use
    ///   - page: The page index in the photbook
    func setAsset(_ asset: Asset, forPage page: Int) {
        productLayouts[page].asset = asset
    }
    
    /// Sets copy as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - text: The copy to use
    ///   - page: The page index in the photbook
    func setText(_ text: String, forPage page: Int) {
        productLayouts[page].text = text
    }
    
    func spreadIndex(for productLayoutIndex: Int) -> Int? {
        guard productLayoutIndex > 0 && productLayoutIndex < productLayouts.count else { return nil }
        var spreadIndex = 0.0
        
        var i = 0
        var index: Int? = nil
        while i < productLayouts.count {
            if i == productLayoutIndex {
                index = Int(spreadIndex)
            }
            
            spreadIndex += productLayouts[i].layout.isDoubleLayout ? 1 : 0.5
            i += 1
        }
        
        return index
    }
    
    func productLayoutIndex(for spreadIndex: Int) -> Int? {
        var spreadIndexCount = 1 // Skip the first spread which includes the courtesy page
        var i = 2 // Skip the cover and the page on the first spread
        while i < productLayouts.count {
            if spreadIndex == spreadIndexCount {
                return i
            }
            i += productLayouts[i].layout.isDoubleLayout ? 1 : 2
            spreadIndexCount += 1
        }
        
        return nil
    }
    
    func addPage(at index: Int) {
        addPages(at: index, number: 1)
    }
    
    func addDoubleSpread(at index: Int) {
        addPages(at: index, number: 2)
    }

    func addPages(at index: Int, pages: [ProductLayout]) {
        addPages(at: index, number: pages.count, pages: pages)
    }
    
    private func addPages(at index: Int, number: Int, pages: [ProductLayout]? = nil) {
        let newProductLayouts = pages ?? createLayoutsForAssets(assets: [], from: layouts, placeholderLayouts: number)
        
        productLayouts.insert(contentsOf: newProductLayouts, at: index)
    }
    
    func deletePages(for productLayout: ProductLayout) {
        guard let index = productLayouts.firstIndex(where: { $0 === productLayout }) else { return }
        productLayouts.remove(at: index)
        
        if !productLayout.layout.isDoubleLayout {
            productLayouts.remove(at: index)
        }
    }
    
    func pageType(forLayoutIndex index: Int) -> PageType {
        if index == 0 { return .cover }
        if index == 1 { return .first }
        if index == productLayouts.count - 1 { return .last }
        
        let doublePagesBeforeIndex = Array(productLayouts[0..<index]).filter { $0.layout.isDoubleLayout }.count
        
        if doublePagesBeforeIndex > 0 {
            return (index - doublePagesBeforeIndex) % 2 == 0 ? .left : .right
        }
        if index % 2 == 0 { return .left }
        return .right
    }
    
    func moveLayout(from fromIndex: Int, to toIndex: Int) {
        let fromProductLayout = productLayouts[fromIndex]
        let toProductLayout = productLayouts[toIndex]
        
        let movingDown = fromIndex < toIndex
        
        if movingDown {
            if fromProductLayout.layout.isDoubleLayout && toProductLayout.layout.isDoubleLayout {
                productLayouts.move(fromIndex, to: toIndex)
            } else if fromProductLayout.layout.isDoubleLayout {
                productLayouts.move(fromIndex, to: toIndex + 1)
            } else if toProductLayout.layout.isDoubleLayout {
                productLayouts.move(fromIndex + 1, to: toIndex)
                productLayouts.move(fromIndex, to: toIndex - 1)
            } else {
                productLayouts.move(fromIndex + 1, to: toIndex + 1)
                productLayouts.move(fromIndex, to: toIndex)
            }
        } else {
            productLayouts.move(fromIndex, to: toIndex)
            
            if !fromProductLayout.layout.isDoubleLayout {
                productLayouts.move(fromIndex + 1, to: toIndex + 1)
            }
        }
    }
    
    func replaceLayout(at index: Int, with productLayout: ProductLayout, pageType: PageType?) {
        let previousLayout = productLayouts[index]
        productLayouts[index] = productLayout
        
        if previousLayout.layout.isDoubleLayout != productLayout.layout.isDoubleLayout {
            // From single to double
            if productLayout.layout.isDoubleLayout {
                if pageType == .left {
                    productLayouts.remove(at: index + 1)
                } else if pageType == .right {
                    productLayouts.remove(at: index - 1)
                }
            } else {
                addPage(at: index + 1)
            }
        }
    }
    
    func bleed(forPageSize size: CGSize, type: PageType? = nil) -> CGFloat {
        let pageHeight = type != nil && type! == .cover ? photobookTemplate.coverSize.height : photobookTemplate.pageSize.height
        let scaleFactor = size.height / pageHeight
        return photobookTemplate.pageBleed * scaleFactor
    }
    
    func pdfParameters() -> [String: Any]? {
        
        var photobook = [String: Any]()
        
        // Pages
        var pages = [[String: Any]]()
        for (index, productLayout) in productLayouts.enumerated() {
            var page = [String: Any]()
            
            var layoutBoxes = [[String: Any]]()
            
            let isCover = index == 0
            let isDoubleLayout = productLayout.layout.isDoubleLayout
            
            let templateSize = isCover ? photobookTemplate.coverSize : photobookTemplate.pageSize
            let pageSize = CGSize(width: isDoubleLayout ? templateSize.width * 2 : templateSize.width, height: templateSize.height)
            let pageType = self.pageType(forLayoutIndex: index)
            
            // Image layout box
            if let asset = productLayout.asset,
                let imageLayoutBox = productLayout.layout.imageLayoutBox,
                let productLayoutAsset = productLayout.productLayoutAsset {
                
                var layoutBox = [String: Any]()
                
                // Work out the bleed rect and adjust the transform
                let containerSize = imageLayoutBox.rectContained(in: pageSize).size

                let bleed = self.bleed(forPageSize: pageSize, type: pageType)
                let bleedRect = imageLayoutBox.bleedRect(in: containerSize, withBleed: bleed)
                productLayoutAsset.containerSize = bleedRect.size
                productLayoutAsset.adjustTransform()
                
                layoutBox["contentType"] = "image"
                layoutBox["isDoubleLayout"] = isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": imageLayoutBox.rect.height, "width": imageLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": imageLayoutBox.rect.origin.x, "y": imageLayoutBox.rect.origin.y]
                
                // Convert transform into css format on the backend
                let assetAspectRatio = asset.size.width / asset.size.height
                
                // 1. translation
                // On web the image with scale factor 1 fills the width of the container and is aligned to the top left corner
                // Calculate the offset in points to centre the image in the container
                let assetWidthWhenFitToWidth = productLayoutAsset.containerSize.width
                let assetHeightWhenFitToWidth = assetWidthWhenFitToWidth / assetAspectRatio
                let yOffset = productLayoutAsset.containerSize.height * 0.5 - assetHeightWhenFitToWidth * 0.5
                var transformX = productLayoutAsset.transform.tx
                var transformY = productLayoutAsset.transform.ty + yOffset

                // Convert to CSS percentages
                transformX = transformX / assetWidthWhenFitToWidth
                transformY = transformY / assetHeightWhenFitToWidth

                // 2. zoom 
                let scaledWidth = asset.size.width * productLayoutAsset.transform.scale
                let zoom = scaledWidth / containerSize.width
                
                // 3. rotation
                let rotation = productLayoutAsset.transform.angle * (180 / .pi)
                
                var containedItem = [String: Any]()
                var picture = [String: Any]()
                picture["url"] = asset.uploadUrl
                picture["dimensions"] = ["height": asset.size.height, "width": asset.size.width]
                picture["thumbnailUrl"] = asset.uploadUrl
                containedItem["picture"] = picture
                containedItem["relativeStartPoint"] = ["x": transformX, "y": transformY]
                containedItem["rotation"] = rotation
                containedItem["zoom"] = zoom // X & Y axes scale should be the same, use the scale for X axis
                containedItem["baseWidthPercent"] = 1
                containedItem["flipped"] = false
                
                layoutBox["containedItem"] = containedItem
                
                layoutBoxes.append(layoutBox)
            }
            
            // Text layout box
            if let text = productLayout.text,
                let textLayoutBox = productLayout.layout.textLayoutBox,
                let productLayoutText = productLayout.productLayoutText {
                
                var layoutBox = [String: Any]()
                
                // Adjust container and transform to page dimensions
                productLayoutText.containerSize = textLayoutBox.rectContained(in: pageSize).size
                
                layoutBox["contentType"] = "text"
                layoutBox["isDoubleLayout"] = isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": textLayoutBox.rect.height, "width": textLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": textLayoutBox.rect.origin.x, "y": textLayoutBox.rect.origin.y]
                
                var containedItem = [String: Any]()
                var font = [String: Any]()
                font["fontFamily"] = productLayoutText.fontType.apiFontFamily
                font["fontSize"] = productLayoutText.fontType.apiPhotobookFontSize
                font["fontWeight"] = productLayoutText.fontType.apiPhotobookFontWeight
                font["lineHeight"] = productLayoutText.fontType.lineHeight
                containedItem["font"] = font
                containedItem["text"] = productLayoutText.htmlText ?? text
                containedItem["color"] = pageType == .cover ? coverColor.fontColor().hex : pageColor.fontColor().hex
                
                layoutBox["containedItem"] = containedItem
                
                layoutBoxes.append(layoutBox)
            }
            
            page["layoutBoxes"] = layoutBoxes
            pages.append(page)
        }
        
        photobook["pages"] = pages
        
        // Product
        photobook["productVariantId"] = photobookTemplate.kiteId
        
        // Config
        var photobookConfig = [String: Any]()
        
        photobookConfig["coverColor"] = coverColor.uiColor().hex
        photobookConfig["pageColor"] = pageColor.uiColor().hex
        
        var spineText = [String: Any]()
        
        spineText["text"] = self.spineText
        spineText["color"] = coverColor.fontColor().hex
        
        var font = [String: Any]()
        
        font["fontFamily"] = spineFontType.apiFontFamily
        font["fontSize"] = spineFontType.apiPhotobookFontSize
        font["fontWeight"] = spineFontType.apiPhotobookFontWeight
        font["lineHeight"] = spineFontType.lineHeight
        
        spineText["font"] = font
        
        photobookConfig["spineText"] = spineText
        
        photobook["photobookConfig"] = photobookConfig
        
        return photobook
    }
    
    func costParameters() -> [String: Any]? {
        guard let options = upsoldOptions,
            let shippingMethod = selectedShippingMethod
            else {
                return nil
        }
        
        return [
            "template_id": upsoldTemplate != nil ? upsoldTemplate!.templateId : template.templateId,
            "multiples": itemCount,
            "shipping_class": shippingMethod.id,
            "options": options,
            "assets": [
                "page_count": numberOfPages,
            ],
            "job_id": identifier
        ]
    }
    
    func orderParameters() -> [String: Any]? {
        guard let options = upsoldOptions,
            let insideUrl = insidePdfUrl,
            let coverUrl = coverPdfUrl,
            let shippingMethod = selectedShippingMethod
            else {
                return nil
        }
        
        return [
            "template_id": template.templateId,
            "multiples": itemCount,
            "shipping_class": shippingMethod.id,
            "options": options,
            "assets": [
                "inside_pdf": insideUrl,
                "cover_pdf": coverUrl,
                "page_count": numberOfPages
            ]
        ]
    }
    
    func assetsToUpload() -> [PhotobookAsset]? {
        var assets = [Asset]()
        for layout in productLayouts {
            guard let asset = layout.asset else { continue }
            assets.append(asset)
        }
        return PhotobookAsset.photobookAssets(with: assets)
    }
    
    func previewImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void) {
        guard let baseUrl = pigBaseUrl else { return }
        
        let fetchClosure = { (_ coverUrl: String) in
            guard let url = Pig.previewImageUrl(withBaseUrlString: baseUrl, coverUrlString: coverUrl, size: size) else {
                return
            }
            Pig.fetchPreviewImage(with: url, completion: { image in
                completionHandler(image)
            })
        }
        
        if let coverUrl = pigCoverUrl { // Fetch the preview image if the cover URL is available
            fetchClosure(coverUrl)
        } else if let coverSnapshot = coverSnapshot { // Upload cover otherwise
            Pig.uploadImage(coverSnapshot) { [weak welf = self] result in
                guard let coverUrl = try? result.get() else { return }
                welf?.pigCoverUrl = coverUrl
                fetchClosure(coverUrl)
            }
        }
    }
    
    var photobookApiManager = PhotobookAPIManager()
    
    func processUploadedAssets(completionHandler: @escaping (Error?) -> Void) {
        photobookApiManager.createPdf(withPhotobook: self) { [weak welf = self] result in
            guard let stelf = welf else { return }
            
            switch result {
            case .success(let urls):
                guard urls.count >= 2 else {
                    Analytics.shared.trackError(.pdfCreation)
                    completionHandler(OrderProcessingError.uploadProcessing)
                    return
                }
                stelf.coverPdfUrl = urls[0]
                stelf.insidePdfUrl = urls[1]
                completionHandler(nil)
            case .failure(let error):
                Analytics.shared.trackError(.pdfCreation)
                completionHandler(error)
            }
        }
    }
}

extension PhotobookProduct {

    static func ==(lhs: PhotobookProduct, rhs: PhotobookProduct) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(upsoldTemplate != nil ? upsoldTemplate!.templateId : photobookTemplate.templateId)
        if let upsoldOptions = upsoldOptions {
            hasher.combine(upsoldOptions.description)
        }
        hasher.combine(itemCount)
        hasher.combine(numberOfPages)
        return hasher.finalize()
    }
}
