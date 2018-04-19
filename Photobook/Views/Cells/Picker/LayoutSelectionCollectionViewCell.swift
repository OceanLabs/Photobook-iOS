//
//  LayoutSelectionCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 19/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class LayoutSelectionCollectionViewCell: BorderedCollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(LayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    private struct Constants {
        static let photobookAlignmentMargin: CGFloat = 10.0
    }
    
    // Constraints
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView!
    @IBOutlet private weak var leftAssetContainerView: UIView!
    @IBOutlet private weak var leftAssetImageView: UIImageView!
    @IBOutlet private weak var rightAssetContainerView: UIView!
    @IBOutlet private weak var rightAssetImageView: UIImageView!
    @IBOutlet private var photobookLeftAligmentConstraint: NSLayoutConstraint!
    @IBOutlet private var photobookTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet private var photobookBottomMarginConstraint: NSLayoutConstraint!
    @IBOutlet private var photobookLeadMarginConstraint: NSLayoutConstraint!
    @IBOutlet private var photobookTrailMarginConstraint: NSLayoutConstraint!
    
    var pageType: PageType!
    var layout: Layout?
    var asset: Asset!
    var image: UIImage!
    var oppositeImage: UIImage!
    var pageIndex: Int?
    var coverColor: ProductColor!
    var pageColor: ProductColor!
    var isEditingDoubleLayout = false // True if the original layout was a double page
    
    private var pageView: PhotobookPageView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return photobookFrameView.leftPageView
        case .right, .first:
            return photobookFrameView.rightPageView
        default:
            return nil
        }
    }
    
    private var oppositePageView: PhotobookPageView? {
        switch pageType {
        case .left:
            return photobookFrameView.rightPageView
        case .right:
            return photobookFrameView.leftPageView
        default:
            return nil
        }
    }

    private weak var assetContainerView: UIView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return leftAssetContainerView
        case .right, .first:
            return rightAssetContainerView
        default:
            return nil
        }
    }
    
    private weak var assetImageView: UIImageView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return leftAssetImageView
        case .right, .first:
            return rightAssetImageView
        default:
            return nil
        }
    }
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    func setupLayout() {
        guard let pageIndex = pageIndex, let layout = layout else { return }

        backgroundColor = .clear

        photobookFrameView.leftPageView.shouldSetImage = true
        photobookFrameView.rightPageView.shouldSetImage = true
        
        let aspectRatio = product.template.aspectRatio!
        if layout.isDoubleLayout {
            photobookFrameView.leftPageView.aspectRatio = pageType == .left ? aspectRatio * 2.0 : 0.0
            photobookFrameView.rightPageView.aspectRatio = pageType == .left ? 0.0 : aspectRatio * 2.0
        } else {
            photobookFrameView.leftPageView.aspectRatio = aspectRatio
            photobookFrameView.rightPageView.aspectRatio = aspectRatio
        }
        
        photobookLeftAligmentConstraint.isActive = !layout.isDoubleLayout
        photobookLeadMarginConstraint.isActive = layout.isDoubleLayout
        photobookTrailMarginConstraint.isActive = layout.isDoubleLayout
        photobookTopMarginConstraint.isActive = !layout.isDoubleLayout
        photobookBottomMarginConstraint.isActive = !layout.isDoubleLayout

        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = asset

        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
        
        switch pageType! {
        case .last:
            photobookFrameView.isRightPageVisible = false
            fallthrough
        case .left where !layout.isDoubleLayout:
            photobookLeftAligmentConstraint.constant = bounds.width - Constants.photobookAlignmentMargin
        case .first:
            photobookFrameView.isLeftPageVisible = false
        default:
            break
        }
        photobookFrameView.layoutIfNeeded()
        
        pageView.pageIndex = pageIndex
        pageView.productLayout = productLayout
        pageView.setupImageBox(with: image)
        pageView.setupTextBox(mode: .linesPlaceholder)
        
        // Setup the opposite layout if necessary
        if !layout.isDoubleLayout && !isEditingDoubleLayout && (pageType == .left || pageType == .right) {
            let oppositeIndex = pageIndex + (pageType == .left ? 1 : -1)
            oppositePageView!.pageIndex = oppositeIndex
            oppositePageView!.productLayout = product.productLayouts[oppositeIndex].shallowCopy()
            oppositePageView!.setupImageBox(with: oppositeImage, animated: false)
            oppositePageView!.setupTextBox(mode: .userTextOnly)
        }

        if photobookFrameView.coverColor != coverColor ||
            photobookFrameView.pageColor != pageColor {
                photobookFrameView.coverColor = coverColor
                photobookFrameView.pageColor = pageColor
                photobookFrameView.resetPageColor()
        }
        
        setup(reset: true)
    }
    
    override func prepareForReuse() {
        photobookLeftAligmentConstraint.isActive = false
        photobookLeadMarginConstraint.isActive = false
        photobookTrailMarginConstraint.isActive = false
        photobookTopMarginConstraint.isActive = false
        photobookBottomMarginConstraint.isActive = false
    }
}

extension LayoutSelectionCollectionViewCell: LayoutSelectionCollectionViewCellSetup {}
