//
//  ColorSelectionViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol ColorSelectorDelegate: class {
    func didSelect(_ color: ProductColor)
}


class ColorSelectionViewController: UIViewController {
    
    private var productColors: [ProductColor] = [ .white, .black ]

    @IBOutlet var productColorButtons: [ProductColorButtonView]! {
        didSet {
            for (i, productColorButton) in productColorButtons.enumerated() {
                productColorButton.productColor = productColors[i]
                productColorButton.isBorderVisible = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

class ProductColorButtonView: BorderedRoundedView {
    
    var productColor: ProductColor! {
        didSet {
            guard let productColor = productColor else { return }
            switch productColor {
            case .white: color = .white
            case .black: color = .black
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        roundedBorderWidth = 4.0
    }
}
