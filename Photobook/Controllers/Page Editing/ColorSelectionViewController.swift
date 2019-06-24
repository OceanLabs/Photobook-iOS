//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
            let index = productColors.firstIndex(of: selectedColor)
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
        guard let index = productColorButtons.firstIndex(of: button),
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
