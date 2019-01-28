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

class DoubleStoryTableViewCell: StoryTableViewCell {
    
    override class func reuseIdentifier() -> String {
        return NSStringFromClass(DoubleStoryTableViewCell.self).components(separatedBy: ".").last!
    }

    @IBOutlet private weak var secondTitleLabel: UILabel!
    @IBOutlet private weak var secondDatesLabel: UILabel!
    @IBOutlet private weak var secondSelectedCountLabel: UILabel!
    @IBOutlet weak var secondCoverImageView: UIImageView!
    @IBOutlet weak var secondContainerView: UIView!
    @IBOutlet weak var secondOverlayView: UIView!
    
    var secondTitle: String? {
        didSet {
            secondTitleLabel.text = secondTitle
            secondTitleLabel.setLineHeight(secondTitleLabel.font.pointSize)
        }
    }
    var secondDates: String? { didSet { secondDatesLabel.text = secondDates } }
    var secondCount: Int? {
        didSet {
            guard secondCount != nil && secondCount! > 0 else {
                secondSelectedCountLabel.isHidden = true
                return
            }
            secondSelectedCountLabel.isHidden = false
            secondSelectedCountLabel.text = "\(secondCount!)"
        }
    }
    
    @IBAction func tappedSecondStory(_ sender: UIButton) {
        guard let storyIndex = storyIndex else {
            fatalError("Story index not set")
        }
        delegate?.didTapOnStory(index: storyIndex + 1, coverImage: secondCoverImageView.image, sourceView: secondCoverImageView.superview, labelsContainerView: secondTitleLabel.superview)
    }
    
    override func prepareForReuse() {
        coverImageView.image = nil
        secondCoverImageView.image = nil
    }
}
