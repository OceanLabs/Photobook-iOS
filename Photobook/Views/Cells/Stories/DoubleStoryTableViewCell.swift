//
//  DoubleStoryTableViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class DoubleStoryTableViewCell: StoryTableViewCell {
    
    override class func reuseIdentifier() -> String {
        return NSStringFromClass(DoubleStoryTableViewCell.self).components(separatedBy: ".").last!
    }

    @IBOutlet private weak var secondTitleLabel: UILabel!
    @IBOutlet private weak var secondDatesLabel: UILabel!
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
