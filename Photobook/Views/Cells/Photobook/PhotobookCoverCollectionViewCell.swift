//
//  PhotobookCoverCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookCoverCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var spineFrameView: SpineFrameView! {
        didSet {
            spineFrameView.color = ProductManager.shared.coverColor
            spineFrameView.spineText = ProductManager.shared.spineText
        }
    }
    @IBOutlet private weak var coverFrameView: CoverFrameView! {
        didSet {
            coverFrameView.color = ProductManager.shared.coverColor
        }
    }
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet {
            coverFrameView.pageView.imageSize = imageSize
        }
    }
    var width: CGFloat! { didSet { coverFrameView.width = width } }
    
    weak var delegate: PhotobookPageViewDelegate? { didSet { coverFrameView.pageView.delegate = delegate } }
    
    func loadCover() {
        coverFrameView.pageView.setupImageBox()
    }
}

