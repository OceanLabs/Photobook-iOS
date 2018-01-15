//
//  AssetSelectorAddMoreCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AssetSelectorAddMoreCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = NSStringFromClass(AssetSelectorAddMoreCollectionViewCell.self).components(separatedBy: ".").last!

    @IBOutlet weak var backgroundColorView: UIView! {
        didSet {
            backgroundColorView.bezierRoundedCorners(withRadius: BorderedCollectionViewCell.cornerRadius)
        }
    }
}

