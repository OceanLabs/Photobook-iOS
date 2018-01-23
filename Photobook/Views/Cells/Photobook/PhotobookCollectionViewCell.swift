//
//  PhotobookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

@objc protocol PhotobookCollectionViewCellDelegate: class, UIGestureRecognizerDelegate {
    func didTapOnPlusButton(at foldIndex: Int)
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer)
    @objc func didPan(_ sender: UIPanGestureRecognizer)
}

class PhotobookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView!
    @IBOutlet private weak var plusButton: UIButton!

    static let reuseIdentifier = NSStringFromClass(PhotobookCollectionViewCell.self).components(separatedBy: ".").last!
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet {
            photobookFrameView.leftPageView.imageSize = imageSize
            photobookFrameView.rightPageView.imageSize = imageSize
        }
    }
    var aspectRatio: CGFloat = 1.0 {
        didSet {
            photobookFrameView.leftPageView.aspectRatio = aspectRatio
            photobookFrameView.rightPageView.aspectRatio = aspectRatio
        }
    }
    
    var leftIndex: Int? { return photobookFrameView.leftPageView.index }
    var rightIndex: Int? { return photobookFrameView.rightPageView.index }
    var width: CGFloat! { didSet { photobookFrameView.width = width } }
    var coverColor: ProductColor! { didSet { photobookFrameView.coverColor = coverColor } }
    var pageColor: ProductColor! { didSet { photobookFrameView.pageColor = pageColor } }
    var isVisible: Bool {
        get { return !photobookFrameView.isHidden }
        set { photobookFrameView.isHidden = !newValue }
    }
    var isPlusButtonVisible: Bool {
        get { return !plusButton.isHidden }
        set { plusButton.isHidden = !isPlusButtonVisible }
    }
    
    weak var delegate: PhotobookCollectionViewCellDelegate?
    weak var pageDelegate: PhotobookPageViewDelegate? {
        didSet {
            photobookFrameView.leftPageView.delegate = pageDelegate
            photobookFrameView.rightPageView.delegate = pageDelegate
        }
    }

    func loadPage(_ page: PageSide, index: Int?, layout: ProductLayout? = nil) {
        switch page {
        case .left:
            guard let index = index else {
                photobookFrameView.isLeftPageVisible = false
                return
            }
            photobookFrameView.isLeftPageVisible = true
            photobookFrameView.leftPageView.index = index
            if layout != nil { photobookFrameView.leftPageView.productLayout = layout }
            
            photobookFrameView.leftPageView.setupLayoutBoxes()
        case .right:
            guard let index = index else {
                photobookFrameView.isRightPageVisible = false
                return
            }
            photobookFrameView.isRightPageVisible = true
            photobookFrameView.rightPageView.index = index
            if layout != nil { photobookFrameView.rightPageView.productLayout = layout }
            
            photobookFrameView.rightPageView.setupLayoutBoxes()
        }
    }
    
    @IBAction func didTapPlus(_ sender: UIButton) {
        guard let layoutIndex = photobookFrameView.leftPageView.index ?? photobookFrameView.rightPageView.index,
            let foldIndex = ProductManager.shared.foldIndex(for: layoutIndex)
            else { return }
        delegate?.didTapOnPlusButton(at: foldIndex)
    }
    
    func setIsRearranging(_ isRearranging: Bool) {
        photobookFrameView.leftPageView.isUserInteractionEnabled = !isRearranging
        photobookFrameView.rightPageView.isUserInteractionEnabled = !isRearranging
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

