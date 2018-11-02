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

/// A collectionView cell that can have rounded border around it
class BorderedCollectionViewCell: UICollectionViewCell, BorderedViewProtocol {
    static let cornerRadius: CGFloat = 11.0
    
    @IBOutlet weak var roundedBackgroundView: UIView! { didSet { setupRoundedBackgroundView() } }
    
    var borderLayer: CAShapeLayer!
    var isBorderVisible = false { willSet { setBorderVisible(newValue) } }

    var roundedBorderColor: UIColor? { didSet { setup(reset: true) } }
    var roundedBorderWidth: CGFloat? = 4.0 { didSet { setup(reset: true) } }
    var roundedCornerRadius: CGFloat? = BorderedCollectionViewCell.cornerRadius { didSet { setup(reset: true) } }
    var color: UIColor! = UIColor(red: 0.79, green: 0.8, blue: 0.8, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
