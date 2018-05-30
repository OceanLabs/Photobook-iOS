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

    weak var delegate: ColorSelectorDelegate?
    var selectedColor: ProductColor! {
        didSet {
            guard productColorButtons != nil else { return }
            let index = productColors.index(of: selectedColor)
            for (i, productColorButton) in productColorButtons.enumerated() {
                let selected = i == index
                productColorButton.isBorderVisible = selected
                productColorButton.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + productColors[i].accessibilityLabel
                productColorButton.accessibilityHint = !selected ? CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem : nil
            }
        }
    }
    
    private var productColors: [ProductColor] = [ .white, .black ]

    @IBOutlet var productColorButtons: [ProductColorButtonView]! {
        didSet {
            for (i, productColorButton) in productColorButtons.enumerated() {
                productColorButton.productColor = productColors[i]
            }
        }
    }    
}

extension ColorSelectionViewController: ProductColorButtonViewDelegate {
    
    func didTap(on button: ProductColorButtonView) {
        guard let index = productColorButtons.index(of: button),
            index < productColors.count
            else { fatalError("Tapped button with no product color equivalent") }
        
        selectedColor = productColors[index]
        delegate?.didSelect(selectedColor)
    }
}

@objc protocol ProductColorButtonViewDelegate: class {
    func didTap(on button: ProductColorButtonView)
}

class ProductColorButtonView: BorderedRoundedView {
    
    @IBOutlet weak var delegate: ProductColorButtonViewDelegate?
    
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedButton(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @IBAction func tappedButton(_ sender: UIGestureRecognizer) {
        delegate?.didTap(on: self)
    }
}
