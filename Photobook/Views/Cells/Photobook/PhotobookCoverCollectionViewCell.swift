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

protocol PhotobookCoverCollectionViewCellDelegate: class {
    func didTapOnSpine(with rect: CGRect, in containerView: UIView)
    func didTapOnCover(_ cover: PhotobookPageView, with rect: CGRect, in containerView: UIView)
}

class PhotobookCoverCollectionViewCell: UICollectionViewCell, InteractivePagesCell {
    
    static let reuseIdentifier = NSStringFromClass(PhotobookCoverCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var spineButton: UIButton!
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var coverFrameView: CoverFrameView!

    var width: CGFloat! {
        didSet { coverFrameView.width = width }
    }
    
    weak var delegate: PhotobookCoverCollectionViewCellDelegate? {
        didSet { coverFrameView.pageView.delegate = self }
    }
    
    var isPageInteractionEnabled: Bool = false {
        didSet { coverFrameView.isUserInteractionEnabled = isPageInteractionEnabled }
    }
    
    var isFaded: Bool = false {
        didSet {
            coverFrameView.alpha = isFaded ? interactivePageFadedAlpha : 1.0
            spineFrameView.alpha = coverFrameView.alpha
        }
    }
    
    var product: PhotobookProduct! {
        didSet {
            coverFrameView.product = product
            spineFrameView.spineTextRatio = product.photobookTemplate.spineTextRatio
            spineFrameView.coverHeight = product.photobookTemplate.coverSize.height
        }
    }

    override func prepareForReuse() {
        coverFrameView.pageView.shouldSetImage = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverFrameView.aspectRatio = product.photobookTemplate.coverAspectRatio
    }
    
    func loadCoverAndSpine() {
        coverFrameView.pageView.shouldSetImage = true
        
        coverFrameView.pageView.pageIndex = 0
        coverFrameView.pageView.productLayout = product.productLayouts.first
        coverFrameView.pageView.bleed = product.bleed(forPageSize: coverFrameView.pageView.bounds.size, type: .cover)
        coverFrameView.pageView.interaction = .wholePage
        coverFrameView.pageView.setupImageBox()
        coverFrameView.pageView.setupTextBox(mode: .userTextOnly)
        
        if spineFrameView.text != product.spineText ||
            spineFrameView.fontType != product.spineFontType {
                spineFrameView.text = product.spineText
                spineFrameView.fontType = product.spineFontType
                spineFrameView.setNeedsLayout()
                spineFrameView.layoutIfNeeded()
                spineButton.accessibilityValue = product.spineText
            
        }
        
        if coverFrameView.color != product.coverColor {
            coverFrameView.color = product.coverColor
            spineFrameView.color = product.coverColor
            coverFrameView.resetCoverColor()
            spineFrameView.resetSpineColor()
        }
    }
    
    func updateVoiceOver(isRearranging: Bool) {
        if isRearranging {
            coverFrameView.isAccessibilityElement = false
        } else {
            coverFrameView.isAccessibilityElement = true
            coverFrameView.accessibilityLabel = NSLocalizedString("Accessibility/PhotobookPreview/CoverLabel", value: "Cover", comment: "Accessibility label for the book cover")
            coverFrameView.accessibilityHint = CommonLocalizedStrings.accessibilityDoubleTapToEdit
        }
    }
    
    @IBAction func tappedOnSpine(_ sender: UIButton) {
        delegate?.didTapOnSpine(with: spineFrameView.frame, in: spineFrameView.superview!)
    }
}

extension PhotobookCoverCollectionViewCell: PhotobookPageViewDelegate {
    
    func didTapOnPage(_ page: PhotobookPageView, at index: Int) {
        delegate?.didTapOnCover(page, with: coverFrameView.frame, in: self)
    }
}

