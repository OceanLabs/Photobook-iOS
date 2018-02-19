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
    func didTapOnPage(at: Int)
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer)
    @objc func didPan(_ sender: UIPanGestureRecognizer)
}

class PhotobookCollectionViewCell: UICollectionViewCell, InteractivePagesCell {
    
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView! {
        didSet {
            photobookFrameView.coverColor = ProductManager.shared.coverColor
            photobookFrameView.pageColor = ProductManager.shared.pageColor
            //photobookFrameView.aspectRatio = ProductManager.shared.product!.aspectRatio
        }
    }
    @IBOutlet private weak var plusButton: UIButton!

    static let reuseIdentifier = NSStringFromClass(PhotobookCollectionViewCell.self).components(separatedBy: ".").last!
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet {
            photobookFrameView.leftPageView.imageSize = imageSize
            photobookFrameView.rightPageView.imageSize = imageSize
        }
    }
    
    var leftIndex: Int? { return photobookFrameView.leftPageView.pageIndex }
    var rightIndex: Int? { return photobookFrameView.rightPageView.pageIndex }
    var width: CGFloat! { didSet { photobookFrameView.width = width } }
    var isVisible: Bool {
        get { return !photobookFrameView.isHidden }
        set { photobookFrameView.isHidden = !newValue }
    }
    
    weak var delegate: PhotobookCollectionViewCellDelegate?
    weak var pageDelegate: PhotobookPageViewDelegate? {
        didSet {
            photobookFrameView.leftPageView.delegate = pageDelegate
            photobookFrameView.rightPageView.delegate = pageDelegate
        }
    }
    
    var isPlusButtonVisible: Bool {
        get { return !plusButton.isHidden }
        set { plusButton.isHidden = !newValue }
    }
    
    var isPageInteractionEnabled: Bool = false {
        didSet {
            photobookFrameView.leftPageView.isUserInteractionEnabled = isPageInteractionEnabled
            photobookFrameView.rightPageView.isUserInteractionEnabled = isPageInteractionEnabled
        }
    }
    
    var isFaded: Bool = false {
        didSet { photobookFrameView.alpha = isFaded ? interactivePageFadedAlpha : 1.0 }
    }

    func loadPages(leftIndex: Int?, rightIndex: Int?) {
        if let leftIndex = leftIndex {
            photobookFrameView.leftPageView.pageIndex = leftIndex
            photobookFrameView.leftPageView.productLayout = ProductManager.shared.productLayouts[leftIndex]
            
            photobookFrameView.leftPageView.setupImageBox()
            photobookFrameView.leftPageView.setupTextBox(mode: .userTextOnly)
            
            photobookFrameView.isLeftPageVisible = true
            photobookFrameView.leftPageView.interaction = .wholePage
        } else {
            photobookFrameView.isLeftPageVisible = false
            photobookFrameView.leftPageView.interaction = .disabled
        }
        
        if let rightIndex = rightIndex {
            photobookFrameView.rightPageView.pageIndex = rightIndex
            photobookFrameView.rightPageView.productLayout = ProductManager.shared.productLayouts[rightIndex]
            
            photobookFrameView.rightPageView.setupImageBox()
            photobookFrameView.rightPageView.setupTextBox(mode: .userTextOnly)
            
            photobookFrameView.isRightPageVisible = true
            photobookFrameView.rightPageView.interaction = .wholePage
        } else {
            photobookFrameView.isRightPageVisible = false
            photobookFrameView.rightPageView.interaction = .disabled
        }
        
        let aspectRatio = ProductManager.shared.product!.aspectRatio
        if let aspectRatio = aspectRatio, let leftIndex = leftIndex {
            let isDoubleLayout = ProductManager.shared.productLayouts[leftIndex].layout.isDoubleLayout
            photobookFrameView.leftPageView.aspectRatio = isDoubleLayout ? aspectRatio * 2.0 : aspectRatio
            photobookFrameView.rightPageView.aspectRatio = isDoubleLayout ? 0.1 : aspectRatio
        } else {
            photobookFrameView.leftPageView.aspectRatio = aspectRatio
            photobookFrameView.rightPageView.aspectRatio = aspectRatio
        }
        
        photobookFrameView.leftPageView.delegate = self
        photobookFrameView.rightPageView.delegate = self
        
        if photobookFrameView.coverColor != ProductManager.shared.coverColor ||
            photobookFrameView.pageColor != ProductManager.shared.pageColor {
            
            photobookFrameView.coverColor = ProductManager.shared.coverColor
            photobookFrameView.pageColor = ProductManager.shared.pageColor
            photobookFrameView.resetPageColor()
        }
    }
        
    @IBAction func didTapPlus(_ sender: UIButton) {
        guard let layoutIndex = photobookFrameView.leftPageView.pageIndex ?? photobookFrameView.rightPageView.pageIndex,
            let foldIndex = ProductManager.shared.spreadIndex(for: layoutIndex)
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
    
    func didTapOnPage(at index: Int) {
        delegate?.didTapOnPage(at: index)
    }
    
}

