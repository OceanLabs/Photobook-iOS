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
        static let photobookAlignmentMargin: CGFloat = 6.0
        static let photobookVerticalMargin: CGFloat = 6.0
    }
    
    // Constraints
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView!
    @IBOutlet private weak var leftAssetContainerView: UIView!
    @IBOutlet private weak var leftAssetImageView: UIImageView!
    @IBOutlet private weak var rightAssetContainerView: UIView!
    @IBOutlet private weak var rightAssetImageView: UIImageView!
    @IBOutlet private weak var photobookLeftAligmentConstraint: NSLayoutConstraint!

    var pageType: PageType!
    var layout: Layout?
    var asset: Asset!
    var image: UIImage!
    var pageIndex: Int?
    var coverColor: ProductColor!
    var pageColor: ProductColor!
    var isDoublePage: Bool!
    
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
        
    func setupLayout() {
        guard let pageIndex = pageIndex, let layout = layout else { return }

        backgroundColor = .clear
        
        let aspectRatio = ProductManager.shared.product!.aspectRatio!
        let hadEqualAspectRatios = photobookFrameView.leftPageView.aspectRatio == nil || (photobookFrameView.leftPageView.aspectRatio! ~= photobookFrameView.rightPageView.aspectRatio!)
        if layout.isDoubleLayout {
            photobookFrameView.leftPageView.aspectRatio = pageType == .left ? aspectRatio * 2.0 : 0.0
            photobookFrameView.rightPageView.aspectRatio = pageType == .left ? 0.0 : aspectRatio * 2.0
            if hadEqualAspectRatios {
                photobookFrameView.resetPageColor()
            }
        } else {
            photobookFrameView.leftPageView.aspectRatio = aspectRatio
            photobookFrameView.rightPageView.aspectRatio = aspectRatio
            if !hadEqualAspectRatios {
                photobookFrameView.resetPageColor()
            }
        }
        photobookFrameView.width = (bounds.height - 2.0 * Constants.photobookVerticalMargin) * aspectRatio * 2.0
        
        photobookFrameView.layoutIfNeeded()
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = asset

        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
        
        switch pageType! {
        case .last:
            photobookFrameView.isRightPageVisible = false
            fallthrough
        case .left:
            photobookLeftAligmentConstraint.constant = bounds.width - Constants.photobookAlignmentMargin
            
            photobookFrameView.leftPageView.pageIndex = pageIndex
            photobookFrameView.leftPageView.productLayout = productLayout
            photobookFrameView.leftPageView.setupImageBox(with: image)
            photobookFrameView.leftPageView.setupTextBox(mode: .linesPlaceholder)
        case .first:
            photobookFrameView.isLeftPageVisible = false
            fallthrough
        case .right:
            photobookFrameView.rightPageView.pageIndex = pageIndex
            photobookFrameView.rightPageView.productLayout = productLayout
            photobookFrameView.rightPageView.setupImageBox(with: image)
            photobookFrameView.rightPageView.setupTextBox(mode: .linesPlaceholder)
        default:
            break
        }
        
        if photobookFrameView.coverColor != coverColor ||
            photobookFrameView.pageColor != pageColor {
                photobookFrameView.coverColor = coverColor
                photobookFrameView.pageColor = pageColor
                photobookFrameView.resetPageColor()
        }
    }
}

