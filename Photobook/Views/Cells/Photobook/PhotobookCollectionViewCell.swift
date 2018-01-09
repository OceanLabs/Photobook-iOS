//
//  PhotobookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bookView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var leftPageView: PhotobookPageView!
    @IBOutlet weak var rightPageView: PhotobookPageView?
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet private var pageAspectRatioConstraint: NSLayoutConstraint!
    
    /* This hidden view is here only to set the aspect ratio of the page,
     because if the aspect ratio constraint is set to one of the non-hidden views,
     the automatic sizing of the cells doesn't work. I don't know why, it might be a bug
     in autolayout.
     */
    @IBOutlet private weak var aspectRatioHelperView: UIView!
    
    func configurePageAspectRatio(_ ratio: CGFloat) {
        aspectRatioHelperView.removeConstraint(pageAspectRatioConstraint)
        pageAspectRatioConstraint = NSLayoutConstraint(item: aspectRatioHelperView, attribute: .width, relatedBy: .equal, toItem: aspectRatioHelperView, attribute: .height, multiplier: ratio, constant: 0)
        pageAspectRatioConstraint.priority = UILayoutPriority(750)
        aspectRatioHelperView.addConstraint(pageAspectRatioConstraint)
    }
}
