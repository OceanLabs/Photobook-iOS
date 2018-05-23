//
//  CoverLayoutSelectionCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class CoverLayoutSelectionCollectionViewCell: BorderedCollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(CoverLayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    private struct Constants {
        static let photobookVerticalMargin: CGFloat = 6.0
    }
    
    @IBOutlet private weak var coverFrameView: CoverFrameView!
    var layout: Layout?
    var asset: Asset!
    var image: UIImage!
    var coverColor: ProductColor!
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    func setupLayout() {
        guard let layout = layout else { return }
        
        backgroundColor = .clear
        
        let aspectRatio = product.template.coverAspectRatio
        
        coverFrameView.width = (bounds.height - 2.0 * Constants.photobookVerticalMargin) * aspectRatio
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = asset
        
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
        coverFrameView.pageView.shouldSetImage = true
        coverFrameView.pageView.pageIndex = 0
        coverFrameView.pageView.productLayout = productLayout
        coverFrameView.pageView.setupImageBox(with: image)
        coverFrameView.pageView.setupTextBox(mode: .linesPlaceholder)
        
        if coverFrameView.color != coverColor {
            coverFrameView.color = coverColor
            coverFrameView.resetCoverColor()
        }
        
        setup(reset: true)
    }
}

extension CoverLayoutSelectionCollectionViewCell: LayoutSelectionCollectionViewCellSetup {}
