//
//  OpenPhotobookCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 12/01/20178.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OpenPhotobookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView!
    
    static let reuseIdentifier = NSStringFromClass(OpenPhotobookCollectionViewCell.self).components(separatedBy: ".").last!
    
    var imageSize = CGSize.zero
    var aspectRatio: CGFloat = 1.0 {
        didSet {
            photobookFrameView.leftPageView.aspectRatio = aspectRatio
            photobookFrameView.rightPageView.aspectRatio = aspectRatio
        }
    }
    
    var width: CGFloat! { didSet { photobookFrameView.width = width } }
    var coverColor: ProductColor! { didSet { photobookFrameView.coverColor = coverColor } }
    var pageColor: ProductColor! { didSet { photobookFrameView.pageColor = pageColor } }
    
    weak var delegate: PhotobookPageViewDelegate? {
        didSet {
            photobookFrameView.leftPageView.delegate = delegate
            photobookFrameView.rightPageView.delegate = delegate
        }
    }
    
    func loadPage(_ page: PageSide, index: Int?) {
        switch page {
        case .left:
            guard let index = index else {
                photobookFrameView.isLeftPageVisible = false
                photobookFrameView.leftPageView.isHidden = true
                return
            }
            photobookFrameView.isLeftPageVisible = true
            photobookFrameView.leftPageView.index = index
            photobookFrameView.leftPageView.load(size: imageSize)
        case .right:
            guard let index = index else {
                photobookFrameView.isRightPageVisible = false
                photobookFrameView.rightPageView.isHidden = true
                return
            }
            photobookFrameView.isRightPageVisible = true
            photobookFrameView.rightPageView.index = index
            photobookFrameView.rightPageView.load(size: imageSize)
        }
    }
}
