//
//  PhotobookCoverCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotobookCoverCollectionViewCellDelegate: class {
    func didTapOnSpine(with rect: CGRect, in containerView: UIView)
    func didTapOnCover()
}

class PhotobookCoverCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var coverFrameView: CoverFrameView! {
        didSet { coverFrameView.interaction = .wholePage }
    }
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet { coverFrameView.pageView.imageSize = imageSize }
    }

    var width: CGFloat! {
        didSet { coverFrameView.width = width }
    }
    
    weak var delegate: PhotobookCoverCollectionViewCellDelegate? {
        didSet { coverFrameView.pageView.delegate = self }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverFrameView.aspectRatio = ProductManager.shared.product!.aspectRatio
    }
    
    func loadCoverAndSpine() {
        coverFrameView.pageView.index = 0
        coverFrameView.pageView.productLayout = ProductManager.shared.productLayouts.first
        coverFrameView.pageView.setupImageBox()
        coverFrameView.pageView.setupTextBox(mode: .userTextOnly)
        
        spineFrameView.text = ProductManager.shared.spineText
        spineFrameView.fontType = ProductManager.shared.spineFontType
        
        if coverFrameView.color != ProductManager.shared.coverColor {
            coverFrameView.color = ProductManager.shared.coverColor
            spineFrameView.color = ProductManager.shared.coverColor
            coverFrameView.resetCoverColor()
            spineFrameView.resetSpineColor()
        }
    }
    
    @IBAction func tappedOnSpine(_ sender: UIButton) {
        delegate?.didTapOnSpine(with: spineFrameView.frame, in: spineFrameView.superview!)
    }
}

extension PhotobookCoverCollectionViewCell: PhotobookPageViewDelegate {
    
    func didTapOnPage(at index: Int) {
        delegate?.didTapOnCover()
    }
}

