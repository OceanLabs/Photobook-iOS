//
//  BorderedCollectionViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// A collectionView cell that can have rounded border around it
class BorderedCollectionViewCell: UICollectionViewCell, BorderedViewProtocol {
    static let cornerRadius: CGFloat = 11.0
    
    @IBOutlet weak var roundedBackgroundView: UIView! { didSet { setupRoundedBackgroundView() } }
    
    var borderLayer: CAShapeLayer!
    var isBorderVisible = false { willSet { setBorderVisible(newValue) } }

    var roundedBorderColor: UIColor? { didSet { setup(reset: true) } }
    var roundedBorderWidth: CGFloat? = 4.0 { didSet { setup(reset: true) } }
    var roundedCornerRadius: CGFloat? = BorderedCollectionViewCell.cornerRadius { didSet { setup(reset: true) } }
    var color: UIColor! = .white

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
