//
//  BorderedRoundedView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// A rounded view with a border
class BorderedRoundedView: UIView, BorderedViewProtocol {
    var borderLayer: CAShapeLayer!
    @IBOutlet weak var roundedBackgroundView: UIView!
    
    var isBorderVisible = false { willSet { setBorderVisible(newValue) } }
    
    var roundedBorderColor: UIColor? { didSet { setup(reset: true) } }
    var roundedBorderWidth: CGFloat? { didSet { setup(reset: true) } }
    var roundedCornerRadius: CGFloat? { didSet { setup(reset: true) } }
    var color: UIColor! = .white
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupRoundedBackgroundView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
