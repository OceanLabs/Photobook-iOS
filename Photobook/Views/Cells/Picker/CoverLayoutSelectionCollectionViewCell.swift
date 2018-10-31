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

class CoverLayoutSelectionCollectionViewCell: BorderedCollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(CoverLayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    private struct Constants {
        static let photobookVerticalMargin: CGFloat = 6.0
    }
    
    @IBOutlet private weak var coverFrameView: CoverFrameView!
    var layout: Layout?
    var asset: Asset!
    var image: UIImage!
    var coverColor: ProductColor!
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    func setupLayout() {
        guard let layout = layout else { return }
        
        backgroundColor = .clear
        
        let aspectRatio = product.photobookTemplate.coverAspectRatio
        
        coverFrameView.width = (bounds.height - 2.0 * Constants.photobookVerticalMargin) * aspectRatio
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = asset
        
        let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
        coverFrameView.pageView.shouldSetImage = true
        coverFrameView.pageView.pageIndex = 0
        coverFrameView.pageView.productLayout = productLayout
        coverFrameView.pageView.setupImageBox(with: image)
        coverFrameView.pageView.setupTextBox(mode: .linesPlaceholder)
        
        if coverFrameView.color != coverColor {
            coverFrameView.color = coverColor
            coverFrameView.resetCoverColor()
        }
        
        setup(reset: true)
    }
}

extension CoverLayoutSelectionCollectionViewCell: LayoutSelectionCollectionViewCellSetup {}
