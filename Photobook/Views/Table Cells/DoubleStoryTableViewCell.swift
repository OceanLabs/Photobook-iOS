//
//  DoubleStoryTableViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class DoubleStoryTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(DoubleStoryTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var leftTitleLabel: UILabel!
    @IBOutlet private weak var leftDatesLabel: UILabel!
    @IBOutlet private weak var leftCoverImageView: UIImageView!
    @IBOutlet private weak var rightTitleLabel: UILabel!
    @IBOutlet private weak var rightDatesLabel: UILabel!
    @IBOutlet private weak var rightCoverImageView: UIImageView!
    
    var leftStoryViewModel: StoryViewModel? {
        didSet {
            leftTitleLabel.text = leftStoryViewModel?.title //setTextWithLineSpacing(text: leftStoryViewModel?.title, lineHeightMultiple: 0.9)
            leftDatesLabel.text = leftStoryViewModel?.dates
            leftCoverImageView.image = leftStoryViewModel?.image
        }
    }
    
    var rightStoryViewModel: StoryViewModel? {
        didSet {
            rightTitleLabel.text = rightStoryViewModel?.title
            rightDatesLabel.text = rightStoryViewModel?.dates
            rightCoverImageView.image = rightStoryViewModel?.image
        }
    }
}
