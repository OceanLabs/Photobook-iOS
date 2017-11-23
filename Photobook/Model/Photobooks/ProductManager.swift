//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

enum ProductColor {
    case white, black
}

// A page in the user's photobook
class ProductLayout: Layout {
    var containedItems = [ContainedItem]()
    
    init(layout: Layout, containedItems: [ContainedItem]) {
        super.init(id: layout.id, imageUrl: layout.imageUrl, layoutBoxes: layout.layoutBoxes)
        self.containedItems = containedItems
    }
    
    // Reassigns boxes to ContainedItems if possible, i.e. reassigning images and text to new layoutBoxId.
    // Recalculates origin and size according to the new layouts (images only) for reassigned boxes.
    // Unassigned boxes are persisted.
    func fitItemsInLayout() {
        
        var layoutBoxesCopy = layoutBoxes!
        for containedItem in containedItems {
            for (index, layoutBox) in layoutBoxesCopy.enumerated() {
                guard layoutBox.type == containedItem.type else { continue }

                containedItem.assignTo(layoutBox)
                layoutBoxesCopy.remove(at: index)
            }
        }
    }
    
    /// Sets an asset for a particular box in the page layout caller
    ///
    /// - Parameters:
    ///   - asset: The image asset to use
    ///   - layoutBoxIndex: The container box index in the page layout caller
    func setAsset(_ asset: Asset, layoutBoxIndex: Int) {
        setContainedItem(asset: asset, text: nil, layoutBoxIndex: layoutBoxIndex)
    }
    
    /// Sets copy for a particular box in the page layout caller
    ///
    /// - Parameters:
    ///   - text: The copy to use
    ///   - layoutBoxIndex: The container box index in the page layout caller
    func setText(_ text: String, layoutBoxIndex: Int) {
        setContainedItem(asset: nil, text: text, layoutBoxIndex: layoutBoxIndex)
    }
    
    private func setContainedItem(asset: Asset?, text: String?, layoutBoxIndex: Int) {
        guard layoutBoxIndex < layoutBoxes.count else { return }
        let layoutBox = layoutBoxes[layoutBoxIndex]
        switch layoutBox.type {
        case .photo where asset == nil:
            print("ProductLayout: Asset missing when trying to assign to photo layout box!")
            return
        case .text where text == nil:
            print("ProductLayout: Copy missing when trying to assign to text layout box!")
            return
        default:
            break
        }
        
        var containedItem = containedItems.first(where: { $0.layoutBoxId == layoutBox.id})
        if containedItem == nil { containedItem = ContainedItem() }
        containedItem!.asset = asset
        containedItem!.text = text

        containedItems.append(containedItem!)
    }
}

// A placeholder in the user's photobook with photo, text and edits info
class ContainedItem {
    var layoutBoxId: Int!
    var asset: Asset? {
        didSet {
            guard asset != nil else { return }
            rotation = 0.0
            // TODO: Calculate scale
        }
    }
    var text: String?
    var relativeOrigin = CGPoint.zero
    var scale: CGFloat = 1.0
    var rotation: CGFloat = 0.0
    
    var type: LayoutBoxType {
        return asset != nil ? .photo : .text
    }
    
    func assignTo(_ layoutBox: LayoutBox) {
        layoutBoxId = layoutBox.id
        
        // TODO: Calculate scale
    }
}

class ProductManager {
    static let shared = ProductManager()

    // Public info about photobook products
    private(set) var products: [Photobook]?

    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    // Current photobook
    var product: Photobook?
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    // TODO: Spine
    
    
    /// Requests the photobook details
    ///
    /// - Parameter completion: Completion block with an optional error
    func requestPhotobookDetails(completion:@escaping (Error?)->()) {
        PhotobookAPIManager.shared.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, error) in
            guard error != nil else {
                completion(error!)
                return
            }
            
            welf?.products = photobooks
            welf?.layouts = layouts
        }
    }
    
    /// Sets one of the available layouts for a page number
    ///
    /// - Parameters:
    ///   - layout: The layout to use
    ///   - page: The page index in the photobook
    func setLayout(_ layout: Layout, forPage page: Int) {
        let previousLayout = productLayouts[page]
        // Create a new page layout instance with layout data and the previously added images and text
        let newLayout = ProductLayout(layout: layout, containedItems: previousLayout.containedItems)
        newLayout.fitItemsInLayout()
        productLayouts[page] = newLayout
    }
    
    /// Sets an asset as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - asset: The image asset to use
    ///   - page: The page index in the photbook
    ///   - layoutBoxIndex: The container box index on that page
    func setAsset(_ asset: Asset, page: Int, layoutBoxIndex: Int) {
        let layout = productLayouts[page]
        layout.setAsset(asset, layoutBoxIndex: layoutBoxIndex)
    }
    
    /// Sets copy as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - text: The copy to use
    ///   - page: The page index in the photbook
    ///   - layoutBoxIndex: The container box index on that page
    func setText(_ text: String, page: Int, layoutBoxIndex: Int) {
        let layout = productLayouts[page]
        layout.setText(text, layoutBoxIndex: layoutBoxIndex)
    }
}
