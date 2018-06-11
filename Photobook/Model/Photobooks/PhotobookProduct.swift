//
//  PhotobookProduct.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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

class PhotobookProduct: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case template, productLayouts, coverColor, pageColor, spineText, spineFontType, productUpsellOptions, itemCount, upsoldTemplate, upsoldOptions
    }
    
    private let bleed: CGFloat = 8.5

    private var currentPortraitLayout = 0
    private var currentLandscapeLayout = 0
    
    var template: PhotobookTemplate
    var productUpsellOptions: [UpsellOption]?
    var spineText: String?
    var spineFontType: FontType = .plain
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    var itemCount: Int = 1
    
    var isAddingPagesAllowed: Bool { return template.maxPages >= numberOfPages + 2 }
    var isRemovingPagesAllowed: Bool { return numberOfPages - 2 >= template.minPages }
    
    var numberOfPages: Int {
        let doubleLayouts = productLayouts.filter { $0.layout.isDoubleLayout }.count
        let singleLayouts = productLayouts.count - doubleLayouts - 1 // Don't count the cover
        return singleLayouts + 2 * doubleLayouts
    }
    
    var coverLayouts: [Layout]!
    var layouts: [Layout]!
    
    var upsoldTemplate: PhotobookTemplate?
    var upsoldOptions: [String: Any]?
    
    func setUpsellData(template: PhotobookTemplate?, payload: [String: Any]?) {
        upsoldTemplate = template
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
            
            let pageSize = index == 0 ? template.coverSize : template.pageSize
            
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
        try container.encode(template, forKey: .template)
        try container.encode(productLayouts, forKey: .productLayouts)
        try container.encode(coverColor, forKey: .coverColor)
        try container.encode(pageColor, forKey: .pageColor)
        try container.encode(spineText, forKey: .spineText)
        try container.encode(spineFontType, forKey: .spineFontType)
        try container.encode(productUpsellOptions, forKey: .productUpsellOptions)
        try container.encode(itemCount, forKey: .itemCount)
        try container.encode(upsoldTemplate, forKey: .upsoldTemplate)
        if let upsoldOptions = upsoldOptions,
            let upsoldOptionData = try? JSONSerialization.data(withJSONObject: upsoldOptions, options: []) {
            try container.encode(upsoldOptionData, forKey: .upsoldOptions)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        template = try values.decode(PhotobookTemplate.self, forKey: .template)
        productLayouts = try values.decode([ProductLayout].self, forKey: .productLayouts)
        coverColor = try values.decode(ProductColor.self, forKey: .coverColor)
        pageColor = try values.decode(ProductColor.self, forKey: .pageColor)
        spineText = try values.decodeIfPresent(String.self, forKey: .spineText)
        spineFontType = try values.decode(FontType.self, forKey: .spineFontType)
        productUpsellOptions = try values.decodeIfPresent([UpsellOption].self, forKey: .productUpsellOptions)
        itemCount = try values.decode(Int.self, forKey: .itemCount)
        upsoldTemplate = try values.decodeIfPresent(PhotobookTemplate.self, forKey: .upsoldTemplate)
        if let upsoldOptionsData = try values.decodeIfPresent(Data.self, forKey: .upsoldOptions) {
            upsoldOptions = (try? JSONSerialization.jsonObject(with: upsoldOptionsData, options: [])) as? [String: Any]
        }
    }
    
    init?(template: PhotobookTemplate, assets: [Asset], coverLayouts: [Layout], layouts: [Layout]) {
        guard !coverLayouts.isEmpty, !layouts.isEmpty else {
            print("PhotobookProduct: Missing layouts for selected photobook")
            return nil
        }
        
        self.template = template
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
                coverAsset = assets[Int(arc4random_uniform(UInt32(assets.count) - 1)) + 1] // Exclude 0
            }
        }
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = coverAsset
        let coverLayout = coverLayouts.first(where: { $0.imageLayoutBox != nil } )
        let productLayout = ProductLayout(layout: coverLayout!, productLayoutAsset: productLayoutAsset)
        tempLayouts.append(productLayout)
        
        // Create layouts for the remaining assets
        // Fill minimum pages with Placeholder assets if needed
        let numberOfPlaceholderLayoutsNeeded = max(template.minPages - assets.count - 1, 0)
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
        self.template = template
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
        guard let index = productLayouts.index(where: { $0 === productLayout }) else { return }
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
        let pageHeight = type != nil && type! == .cover ? template.coverSize.height : template.pageSize.height
        let scaleFactor = size.height / pageHeight
        return bleed * scaleFactor
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
            
            let templateSize = isCover ? template.coverSize : template.pageSize
            let pageSize = CGSize(width: isDoubleLayout ? templateSize.width * 2 : templateSize.width, height: templateSize.height)
            
            // Image layout box
            if let asset = productLayout.asset,
                let imageLayoutBox = productLayout.layout.imageLayoutBox,
                let productLayoutAsset = productLayout.productLayoutAsset {
                
                var layoutBox = [String: Any]()
                
                // Adjust container and transform to page dimensions
                productLayoutAsset.containerSize = imageLayoutBox.rectContained(in: pageSize).size
                productLayoutAsset.adjustTransform()
                
                layoutBox["contentType"] = "image"
                layoutBox["isDoubleLayout"] = isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": imageLayoutBox.rect.height, "width": imageLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": imageLayoutBox.rect.origin.x, "y": imageLayoutBox.rect.origin.y]
                
                // Convert transform into css format on the backend
                let assetAspectRatio = asset.size.width / asset.size.height
                
                //1. translation
                //on web the image with scale factor 1 fills the width of the container and is aligned to the top left corner.
                //first we calculate the offset in points to align the image center with the container center
                let yOffset = productLayoutAsset.containerSize.height * 0.5 - productLayoutAsset.containerSize.width * 0.5 * (1.0 / assetAspectRatio) //offset in points to match initial origins within layout
                
                //match anchors
                var transformX = productLayoutAsset.transform.tx
                var transformY = productLayoutAsset.transform.ty + yOffset
                
                //2. zoom
                //on the pdf back-end scale 1 fills the width of the container. scale 1 on ios is original image width
                let scaledWidth = asset.size.width * productLayoutAsset.transform.scale
                let zoom = scaledWidth/productLayoutAsset.containerSize.width
                
                //3. rotation
                //straightfoward as it's just the angle
                let rotation = productLayoutAsset.transform.angle * (180 / .pi)
                
                //convert to css percentages
                transformX = transformX / productLayoutAsset.containerSize.width
                transformY = transformY / (productLayoutAsset.containerSize.height * (1.0 / assetAspectRatio))
                
                var containedItem = [String: Any]()
                var picture = [String: Any]()
                picture["url"] = asset.uploadUrl
                picture["dimensions"] = ["height": asset.size.height, "width": asset.size.width]
                picture["thumbnailUrl"] = asset.uploadUrl //mock data
                containedItem["picture"] = picture
                containedItem["relativeStartPoint"] = ["x": transformX, "y": transformY]
                containedItem["rotation"] = rotation
                containedItem["zoom"] = zoom // X & Y axes scale should be the same, use the scale for X axis
                containedItem["baseWidthPercent"] = 1 //mock data
                containedItem["flipped"] = false
                
                layoutBox["containedItem"] = containedItem
                
                layoutBoxes.append(layoutBox)
            }
            
            //text layout box
            if let text = productLayout.text,
                let textLayoutBox = productLayout.layout.textLayoutBox,
                let productLayoutText = productLayout.productLayoutText {
                
                var layoutBox = [String: Any]()
                
                //adjust container and transform to page dimensions
                productLayoutText.containerSize = textLayoutBox.rectContained(in: pageSize).size
                
                layoutBox["contentType"] = "text"
                layoutBox["isDoubleLayout"] = isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": textLayoutBox.rect.height, "width": textLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": textLayoutBox.rect.origin.x, "y": textLayoutBox.rect.origin.y]
                
                var containedItem = [String: Any]()
                var font = [String: Any]()
                font["fontFamily"] = productLayoutText.fontType.apiFontFamily
                font["fontSize"] = productLayoutText.fontType.apiPhotobookFontSize()
                font["fontWeight"] = productLayoutText.fontType.apiPhotobookFontWeight()
                font["lineHeight"] = productLayoutText.fontType.apiPhotobookLineHeight()
                containedItem["font"] = font
                containedItem["text"] = productLayoutText.htmlText ?? text
                containedItem["color"] = pageColor.fontColor().hex
                
                layoutBox["containedItem"] = containedItem
                
                layoutBoxes.append(layoutBox)
            }
            
            page["layoutBoxes"] = layoutBoxes
            pages.append(page)
        }
        
        photobook["pages"] = pages
        
        // Product
        photobook["productVariantId"] = template.kiteId
        
        // Config
        var photobookConfig = [String: Any]()
        
        photobookConfig["coverColor"] = coverColor.uiColor().hex
        photobookConfig["pageColor"] = pageColor.uiColor().hex
        
        var spineText = [String: Any]()
        
        spineText["text"] = self.spineText
        spineText["color"] = coverColor.fontColor().hex
        
        var font = [String: Any]()
        
        font["fontFamily"] = spineFontType.apiFontFamily
        font["fontSize"] = spineFontType.apiPhotobookFontSize()
        font["fontWeight"] = spineFontType.apiPhotobookFontWeight()
        font["lineHeight"] = spineFontType.apiPhotobookLineHeight()
        
        spineText["font"] = font
        
        photobookConfig["spineText"] = spineText
        
        photobook["photobookConfig"] = photobookConfig
        
        return photobook
    }
    
    func assetsToUpload() -> [Asset] {
        var assets = [Asset]()
        for layout in productLayouts {
            guard let asset = layout.asset else { continue }
            assets.append(asset)
        }
        return assets
    }
}

extension PhotobookProduct: Hashable, Equatable {
    
    static func ==(lhs: PhotobookProduct, rhs: PhotobookProduct) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var hashValue: Int {
        get {
            var stringHash = ""
            
            stringHash += "pt:\(template.id),"
            if let upsoldOptions = upsoldOptions {
                stringHash += "po:\(upsoldOptions)"
            }
            
            return stringHash.hashValue
        }
    }
}
