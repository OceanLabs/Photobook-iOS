//
//  PhotobookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotobookCollectionViewCellDelegate: class {
    func didTapOnPlusButton(at foldIndex: Int)
}

class PhotobookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bookView: PhotobookView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var leftPageView: PhotobookPageView! {
        didSet {
            bookView.leftPageView = leftPageView
        }
    }
    @IBOutlet weak var rightPageView: PhotobookPageView? {
        didSet {
            bookView.rightPageView = rightPageView
        }
    }
    
    /* This hidden view is here only to set the aspect ratio of the page,
     because if the aspect ratio constraint is set to one of the non-hidden views,
     the automatic sizing of the cells doesn't work. I don't know why, it might be a bug
     in autolayout.
     */
    @IBOutlet private weak var aspectRatioHelperView: UIView!
    @IBOutlet weak var obscuringView: UIView!
    @IBOutlet weak var plusButton: UIButton!
    weak var delegate: PhotobookCollectionViewCellDelegate?
    
    @IBAction func didTapPlus(_ sender: UIButton) {
        guard let layoutIndex = leftPageView.index ?? rightPageView?.index,
            let foldIndex = ProductManager.shared.foldIndex(for: layoutIndex)
            else { return }
        delegate?.didTapOnPlusButton(at: foldIndex)
    }
    
    func setIsRearranging(_ isRearranging: Bool) {
        leftPageView.isUserInteractionEnabled = !isRearranging
        rightPageView?.isUserInteractionEnabled = !isRearranging
    }
}

class PhotobookView: UIView {
    weak var leftPageView: PhotobookPageView!
    weak var rightPageView: PhotobookPageView?
    var dragging = false
}
