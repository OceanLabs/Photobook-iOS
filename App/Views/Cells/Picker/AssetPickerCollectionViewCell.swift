//
//  AssetPickerCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPickerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedStatusImageView: UIImageView!
    
    var assetId: String?
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}
