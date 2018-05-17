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
}

class PhotobookProduct: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case template, photobookId, productLayouts, coverColor, pageColor, spineText, spineFontType, productUpsellOptions, itemCount
    }
    
    private unowned var productManager = ProductManager.shared
    
    private let bleed: CGFloat = 8.5

    private var currentPortraitLayout = 0
    private var currentLandscapeLayout = 0
    
    var template: PhotobookTemplate
    var productUpsellOptions: [UpsellOption]? //TODO: Get this from the initial-data endpoint
    var spineText: String?
    var spineFontType: FontType = .plain
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    var itemCount: Int = 1
    
    // The id of the uploaded PDF
    var photobookId: String?
    
    var isAddingPagesAllowed: Bool {
        // TODO: Use pages count instead of assets/layout count
        return productManager.maximumAllowedAssets > productLayouts.count
    }
    var isRemovingPagesAllowed: Bool {
        // TODO: Use pages count instead of assets/layout count
        return productManager.minimumRequiredAssets < productLayouts.count - 1 // Don't include cover for min calculation
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
        
        let pageSize = CGSize(width: template.pageWidth!, height: template.pageHeight!)
        
        for (index, productLayout) in productLayouts.enumerated() {
            guard let textBox = productLayout.layout.textLayoutBox, let text = productLayout.text, text.count > 0 else { continue }
            
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
    
    init?(template: PhotobookTemplate, assets: [Asset], productManager: ProductManager = ProductManager.shared) {
        guard
            let coverLayouts = productManager.coverLayouts(for: template), !coverLayouts.isEmpty,
            let layouts = productManager.layouts(for: template), !layouts.isEmpty
        else {
            print("PhotobookProduct: Missing layouts for selected photobook")
            return nil
        }
        
        self.template = template
        self.productManager = productManager
        
        let imageOnlyLayouts = layouts.filter({ $0.imageLayoutBox != nil })
        
        var tempLayouts = [ProductLayout]()
        
        // Use a random photo for the cover, but not the first
        let productLayoutAsset = ProductLayoutAsset()
        var coverAsset = assets.first
        if assets.count > 1 {
            coverAsset = assets[(Int(arc4random()) % (assets.count - 1)) + 1] // Exclude 0
        }
        productLayoutAsset.asset = coverAsset
        let coverLayout = coverLayouts.first(where: { $0.imageLayoutBox != nil } )
        let productLayout = ProductLayout(layout: coverLayout!, productLayoutAsset: productLayoutAsset)
        tempLayouts.append(productLayout)
        
        // Create layouts for the remaining assets
        // Fill minimum pages with Placeholder assets if needed
        let numberOfPlaceholderLayoutsNeeded = max(template.minimumRequiredAssets - assets.count - 1, 0)
        tempLayouts.append(contentsOf: createLayoutsForAssets(assets: assets, from: imageOnlyLayouts, placeholderLayouts: numberOfPlaceholderLayoutsNeeded))
        productLayouts = tempLayouts
    }
    
    func setTemplate(_ template: PhotobookTemplate, withAssets assets: [Asset]? = nil, coverLayouts: [Layout], layouts: [Layout]) {
        
        // Reset the current layout since we are changing products
        currentLandscapeLayout = 0
        currentPortraitLayout = 0
        
        // Switching products
        self.template = template
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
    
    private func createLayoutsForAssets(assets: [Asset], from layouts:[Layout], placeholderLayouts: Int = 0) -> [ProductLayout] {
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
        guard let layouts = productManager.layouts(for: template)
            else { return }
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
    
    func bleed(forPageSize size: CGSize) -> CGFloat {
        let scaleFactor = size.height / template.pageHeight
        return bleed * scaleFactor
    }
    
    func pdfParameters() -> [String: Any]? {
        
        var photobook = [String: Any]()
        
        //Pages
        var pages = [[String: Any]]()
        for productLayout in productLayouts {
            var page = [String: Any]()
            
            var layoutBoxes = [[String: Any]]()
            
            let isDoubleLayout = productLayout.layout.isDoubleLayout
            let pageSize = CGSize(width: isDoubleLayout ? template.pageWidth * 2 : template.pageWidth, height: template.pageHeight)
            
            //image layout box
            if let asset = productLayout.asset,
                let imageLayoutBox = productLayout.layout.imageLayoutBox,
                let productLayoutAsset = productLayout.productLayoutAsset {
                
                var layoutBox = [String: Any]()
                
                //adjust container and transform to page dimensions
                productLayoutAsset.containerSize = imageLayoutBox.rectContained(in: pageSize).size
                productLayoutAsset.adjustTransform()
                
                layoutBox["contentType"] = "image"
                layoutBox["isDoubleLayout"] = productLayout.layout.isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": imageLayoutBox.rect.height, "width": imageLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": imageLayoutBox.rect.origin.x, "y": imageLayoutBox.rect.origin.y]
                
                //convert transform into css format on the backend
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
                font["fontSizePx"] = productLayoutText.fontType.apiPhotobookFontSizePx()
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
        
        //product
        
        var productVariant = [String:Any]()
        
        productVariant["productVariantId"] = template.id
        
        //config
        var photobookConfig = [String:Any]()
        
        photobookConfig["coverColor"] = coverColor.uiColor().hex
        photobookConfig["pageColor"] = pageColor.uiColor().hex
        
        var spineText = [String:Any]()
        
        spineText["text"] = self.spineText
        spineText["color"] = coverColor.fontColor().hex
        
        var font = [String:Any]()
        
        font["fontFamily"] = spineFontType.apiFontFamily
        font["fontSizePx"] = spineFontType.apiPhotobookFontSizePx()
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
