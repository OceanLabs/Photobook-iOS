//
//  PhotobookCoverCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookCoverCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var coverFrameView: CoverFrameView!
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    var imageSize = CGSize(width: Int.max, height: Int.max) {
        didSet {
            coverFrameView.pageView.imageSize = imageSize
        }
    }
    var aspectRatio: CGFloat = 1.0 { didSet { coverFrameView.aspectRatio = aspectRatio } }
    var width: CGFloat! { didSet { coverFrameView.width = width } }
    var color: ProductColor! {
        didSet {
            spineFrameView.color = color
            coverFrameView.color = color
        }
    }
    var spineText: String? { didSet { spineFrameView.spineText = spineText } }
    
    weak var delegate: PhotobookPageViewDelegate? { didSet { coverFrameView.pageView.delegate = delegate } }
    
    func loadCover() {
        coverFrameView.pageView.setupImageBox()
    }
}

