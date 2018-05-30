//
//  PhotobookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

// Protocol cells conform to enable / disaple page interaction
protocol InteractivePagesCell {
    var interactivePageFadedAlpha: CGFloat { get }
    var isPageInteractionEnabled: Bool { get set }
    var isFaded: Bool { get set }
}

extension InteractivePagesCell {
    var interactivePageFadedAlpha: CGFloat { return 0.5 }
}

@objc protocol PhotobookCollectionViewCellDelegate: class, UIGestureRecognizerDelegate {
    func didTapOnPlusButton(at foldIndex: Int)
    func didTapOnPage(_ page: PhotobookPageView, at: Int, frame: CGRect, in containerView: UIView)
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer)
    @objc func didPan(_ sender: UIPanGestureRecognizer)
}

class PhotobookCollectionViewCell: UICollectionViewCell, InteractivePagesCell {
    
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView! {
        didSet {
            photobookFrameView.coverColor = product.coverColor
            photobookFrameView.pageColor = product.pageColor
        }
    }
    @IBOutlet private weak var plusButton: UIButton!

    static let reuseIdentifier = NSStringFromClass(PhotobookCollectionViewCell.self).components(separatedBy: ".").last!
    
    var leftPageView: PhotobookPageView { return photobookFrameView.leftPageView }
    var rightPageView: PhotobookPageView { return photobookFrameView.rightPageView }
    var leftIndex: Int?
    var rightIndex: Int?
    var width: CGFloat! { didSet { photobookFrameView.width = width } }
    var isVisible: Bool {
        get { return !photobookFrameView.isHidden }
        set { photobookFrameView.isHidden = !newValue }
    }
    
    weak var delegate: PhotobookCollectionViewCellDelegate?
    
    var isPlusButtonVisible: Bool {
        get { return !plusButton.isHidden }
        set { plusButton.isHidden = !newValue }
    }
    
    var isPageInteractionEnabled: Bool = false {
        didSet {
            leftPageView.isUserInteractionEnabled = isPageInteractionEnabled
            rightPageView.isUserInteractionEnabled = isPageInteractionEnabled
        }
    }
    
    var isFaded: Bool = false {
        didSet { photobookFrameView.alpha = isFaded ? interactivePageFadedAlpha : 1.0 }
    }
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    override func prepareForReuse() {
        leftPageView.clearImage()
        leftPageView.shouldSetImage = false
        
        rightPageView.clearImage()
        rightPageView.shouldSetImage = false
    }

    func loadPages() {
        leftPageView.shouldSetImage = true
        rightPageView.shouldSetImage = true
        
        let aspectRatio = product.template.pageAspectRatio
        if let leftIndex = leftIndex {
            let isDoubleLayout = product.productLayouts[leftIndex].layout.isDoubleLayout
            leftPageView.aspectRatio = isDoubleLayout ? aspectRatio * 2.0 : aspectRatio
            rightPageView.aspectRatio = isDoubleLayout ? 0.0 : aspectRatio
        } else {
            leftPageView.aspectRatio = aspectRatio
            rightPageView.aspectRatio = aspectRatio
        }
        photobookFrameView.layoutIfNeeded()
        
        if let leftIndex = leftIndex {
            leftPageView.pageIndex = leftIndex
            leftPageView.productLayout = product.productLayouts[leftIndex]
            leftPageView.bleed = product.bleed(forPageSize: leftPageView.bounds.size)
            
            leftPageView.setupImageBox(with: leftPageView.productLayout?.productLayoutAsset?.currentImage)
            leftPageView.setupTextBox(mode: .userTextOnly)
            
            photobookFrameView.isLeftPageVisible = true
            leftPageView.interaction = .wholePage
        } else {
            photobookFrameView.isLeftPageVisible = false
            leftPageView.interaction = .disabled
        }
        
        // If leftIndex == rightIndex, then it's a double-page layout
        if let rightIndex = rightIndex, leftIndex != rightIndex {
            rightPageView.pageIndex = rightIndex
            rightPageView.productLayout = product.productLayouts[rightIndex]
            rightPageView.bleed = product.bleed(forPageSize: rightPageView.bounds.size)
            
            rightPageView.setupImageBox(with: rightPageView.productLayout?.productLayoutAsset?.currentImage)
            rightPageView.setupTextBox(mode: .userTextOnly)
            
            photobookFrameView.isRightPageVisible = true
            rightPageView.interaction = .wholePage
        } else {
            if rightIndex == nil {
                photobookFrameView.isRightPageVisible = false
            }
            rightPageView.interaction = .disabled
        }
        
        leftPageView.delegate = self
        rightPageView.delegate = self
        
        if photobookFrameView.coverColor != product.coverColor ||
            photobookFrameView.pageColor != product.pageColor {
            
            photobookFrameView.coverColor = product.coverColor
            photobookFrameView.pageColor = product.pageColor
            photobookFrameView.resetPageColor()
        }
        
        if let index = leftIndex {
            plusButton.accessibilityLabel = NSLocalizedString("", value: "Add pages after page \(index - 1)", comment: "")
        }
    }
    
    func updateVoiceOver(isRearranging: Bool) {
        guard leftIndex != nil || rightIndex != nil else { return }
        if isRearranging {
            photobookFrameView.isAccessibilityElement = leftIndex != nil && (rightIndex != nil || product.productLayouts[leftIndex!].layout.isDoubleLayout)
            leftPageView.isAccessibilityElement = false
            rightPageView.isAccessibilityElement = false
            
            if let leftIndex = leftIndex, let rightIndex = rightIndex, leftIndex != rightIndex {
                photobookFrameView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/PagesLabel", value: "Pages \(leftIndex) and \(rightIndex)", comment: "Accessibility label for the book pages' numbers")
                photobookFrameView.accessibilityIdentifier = "Pages \(leftIndex) and \(rightIndex)"
            } else {
                photobookFrameView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/PageLabel", value: "Page \(leftIndex ?? rightIndex!)", comment: "Accessibility label for the book page number")
                photobookFrameView.accessibilityIdentifier = nil
            }
            photobookFrameView.accessibilityHint = NSLocalizedString("Accessibility/PhotobookPreview/DoubleTapForOptionsHint", value: "Double tap for options", comment: "Accessibility hint letting the user know that they can double tap to get options")
        } else {
            photobookFrameView.isAccessibilityElement = false
            leftPageView.isAccessibilityElement = leftIndex != nil
            rightPageView.isAccessibilityElement = rightIndex != nil
            
            if let leftIndex = leftIndex {
                leftPageView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/LeftPageLabel", value: "Page \(leftIndex)", comment: "Accessibility label for the book page number")
                leftPageView.accessibilityHint = CommonLocalizedStrings.accessibilityDoubleTapToEdit
            }
            if let rightIndex = rightIndex {
                rightPageView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/RightPageLabel", value: "Page \(rightIndex)", comment: "Accessibility label for the book page number")
                rightPageView.accessibilityHint = CommonLocalizedStrings.accessibilityDoubleTapToEdit
            }
        }
    }
        
    @IBAction func didTapPlus(_ sender: UIButton) {
        guard let layoutIndex = photobookFrameView.leftPageView.pageIndex ?? photobookFrameView.rightPageView.pageIndex,
            let foldIndex = product.spreadIndex(for: layoutIndex)
            else { return }
        delegate?.didTapOnPlusButton(at: foldIndex)
    }
    
    private var hasSetUpGestures = false
    func setupGestures() {
        guard let delegate = delegate, !hasSetUpGestures else { return }
        hasSetUpGestures = true

        let longPressGesture = UILongPressGestureRecognizer(target: delegate, action: #selector(PhotobookCollectionViewCellDelegate.didLongPress(_:)))
        longPressGesture.delegate = delegate
        photobookFrameView.addGestureRecognizer(longPressGesture)

        let panGesture = UIPanGestureRecognizer(target: delegate, action: #selector(PhotobookCollectionViewCellDelegate.didPan(_:)))
        panGesture.delegate = delegate
        panGesture.maximumNumberOfTouches = 1
        photobookFrameView.addGestureRecognizer(panGesture)
    }
}

extension PhotobookCollectionViewCell: PhotobookPageViewDelegate {
    
    func didTapOnPage(_ page: PhotobookPageView, at index: Int) {
        delegate?.didTapOnPage(page, at: index, frame: photobookFrameView.frame, in: self)
    }
    
}

