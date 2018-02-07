//
//  PhotobookCoverCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookCoverCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var coverFrameView: CoverFrameView!
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet {
            coverFrameView.pageView.imageSize = imageSize
        }
    }
    var width: CGFloat! { didSet { coverFrameView.width = width } }
    
    weak var delegate: PhotobookPageViewDelegate? { didSet { coverFrameView.pageView.delegate = delegate } }

    override func layoutSubviews() {
        super.layoutSubviews()        
        spineFrameView.spineText = ProductManager.shared.spineText
        coverFrameView.aspectRatio = ProductManager.shared.product!.aspectRatio
    }

    func loadCover() {
        coverFrameView.pageView.index = 0
        coverFrameView.pageView.productLayout = ProductManager.shared.productLayouts.first
        coverFrameView.pageView.setupImageBox()
        
        if coverFrameView.color != ProductManager.shared.coverColor {
            coverFrameView.color = ProductManager.shared.coverColor
            spineFrameView.color = ProductManager.shared.coverColor
            coverFrameView.resetCoverColor()
            spineFrameView.resetSpineColor()
        }
    }
}

