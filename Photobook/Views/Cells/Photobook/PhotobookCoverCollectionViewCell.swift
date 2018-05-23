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
    func didTapOnCover(_ cover: PhotobookPageView, with rect: CGRect, in containerView: UIView)
}

class PhotobookCoverCollectionViewCell: UICollectionViewCell, InteractivePagesCell {
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var spineButton: UIButton!
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var coverFrameView: CoverFrameView! {
        didSet { coverFrameView.interaction = .wholePage }
    }

    var width: CGFloat! {
        didSet { coverFrameView.width = width }
    }
    
    weak var delegate: PhotobookCoverCollectionViewCellDelegate? {
        didSet { coverFrameView.pageView.delegate = self }
    }
    
    var isPageInteractionEnabled: Bool = false {
        didSet { coverFrameView.isUserInteractionEnabled = isPageInteractionEnabled }
    }
    
    var isFaded: Bool = false {
        didSet {
            coverFrameView.alpha = isFaded ? interactivePageFadedAlpha : 1.0
            spineFrameView.alpha = coverFrameView.alpha
        }
    }
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }

    override func prepareForReuse() {
        coverFrameView.pageView.shouldSetImage = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverFrameView.aspectRatio = product.template.coverAspectRatio
    }
    
    func loadCoverAndSpine() {
        coverFrameView.pageView.shouldSetImage = true
        
        coverFrameView.pageView.pageIndex = 0
        coverFrameView.pageView.productLayout = product.productLayouts.first
        coverFrameView.pageView.bleed = product.bleed(forPageSize: coverFrameView.pageView.bounds.size, type: .cover)
        coverFrameView.pageView.setupImageBox()
        coverFrameView.pageView.setupTextBox(mode: .userTextOnly)
        
        if spineFrameView.text != product.spineText ||
            spineFrameView.fontType != product.spineFontType {
                spineFrameView.text = product.spineText
                spineFrameView.fontType = product.spineFontType
                spineFrameView.setNeedsLayout()
                spineFrameView.layoutIfNeeded()
                spineButton.accessibilityValue = product.spineText
            
        }
        
        if coverFrameView.color != product.coverColor {
            coverFrameView.color = product.coverColor
            spineFrameView.color = product.coverColor
            coverFrameView.resetCoverColor()
            spineFrameView.resetSpineColor()
        }
    }
    
    func updateVoiceOver(isRearranging: Bool) {
        if isRearranging {
            coverFrameView.isAccessibilityElement = false
        } else {
            coverFrameView.isAccessibilityElement = true
            coverFrameView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/CoverLabel", value: "Cover", comment: "Accessibility label for the book cover")
            coverFrameView.accessibilityHint = CommonLocalizedStrings.accessibilityDoubleTapToEdit
        }
    }
    
    @IBAction func tappedOnSpine(_ sender: UIButton) {
        delegate?.didTapOnSpine(with: spineFrameView.frame, in: spineFrameView.superview!)
    }
}

extension PhotobookCoverCollectionViewCell: PhotobookPageViewDelegate {
    
    func didTapOnPage(_ page: PhotobookPageView, at index: Int) {
        delegate?.didTapOnCover(page, with: coverFrameView.frame, in: self)
    }
}

