//
//  ProductLayout.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

// A page in the user's photobook
class ProductLayout {
    var layout: Layout! {
        didSet {
            self.fitItemsInLayout()
        }
    }
    var productLayoutAsset: ProductLayoutAsset?
    var productLayoutText: ProductLayoutText?
    
    var asset: Asset? {
        get {
            return productLayoutAsset?.asset
        }
        set {
            guard layout.imageLayoutBox != nil else {
                print("ProductLayout: Trying to assign asset to unavailable container")
                return
            }
            if productLayoutAsset == nil { productLayoutAsset = ProductLayoutAsset() }
            productLayoutAsset!.asset = asset
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
            productLayoutText!.text = text
        }
    }
    
    init(layout: Layout, productLayoutAsset: ProductLayoutAsset? = nil, productLayoutText: ProductLayoutText? = nil) {
        self.layout = layout
        self.productLayoutAsset = productLayoutAsset
        self.productLayoutText = productLayoutText
    }
    
    private func fitItemsInLayout() {
        guard layout != nil else { return }
        
        if productLayoutAsset != nil && layout.imageLayoutBox != nil {
            productLayoutAsset!.containerSize = layout.imageLayoutBox!.rect.size
        }
        if productLayoutText != nil && layout.textLayoutBox != nil {
            productLayoutText!.containerSize = layout.textLayoutBox!.rect.size
        }
    }
}

