//
//  PhotoBookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotoBookCollectionViewCellDelegate: class {
    func didTapOnPlusButton(at indexPath: IndexPath?)
}

class PhotoBookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bookView: PhotoBookView!
    @IBOutlet weak var obscuringView: UIView!
    @IBOutlet weak var plusButton: UIButton!
    weak var delegate: PhotoBookCollectionViewCellDelegate?
    
    @IBAction func didTapPlus(_ sender: UIButton) {
        delegate?.didTapOnPlusButton(at: bookView.indexPath)
    }
    
}
