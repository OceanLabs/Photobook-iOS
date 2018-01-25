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
    
    @IBOutlet weak var roundedBackgroundView: UIView! {
        didSet {
            roundedBackgroundView.bezierRoundedCorners(withRadius: BorderedCollectionViewCell.cornerRadius)
        }
    }
    
    var layout: Layout?
    var asset: Asset!
    var image: UIImage!
    
    func setupLayout() {
        guard let layout = layout else { return }
        
        backgroundColor = .clear
        
        let aspectRatio = ProductManager.shared.product!.aspectRatio!
        
        coverFrameView.color = ProductManager.shared.coverColor
        coverFrameView.pageView.isTapGestureEnabled = false
        coverFrameView.width = (bounds.height - 2.0 * Constants.photobookVerticalMargin) * aspectRatio
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = asset
        
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
        coverFrameView.pageView.productLayout = productLayout
        coverFrameView.pageView.setupImageBox(with: image)
        coverFrameView.pageView.setupTextBox(shouldBeLegible: false)
    }
}
