//
//  AssetPickerCoverCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPickerCoverCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var datesLabel: UILabel!
    @IBOutlet private weak var coverImageView: UIImageView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.setLineHeight(titleLabel.font.pointSize)
        }
    }
    var dates: String? { didSet { datesLabel.text = dates } }
    
    func setCover (cover: Asset?, size: CGSize) {
        coverImageView.setAndFadeIn(asset: cover, size: size, completionHandler: nil)
    }
    
}
