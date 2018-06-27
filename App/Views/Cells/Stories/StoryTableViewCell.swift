//
//  StoryTableViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

protocol StoryTableViewCellDelegate: class {
    func didTapOnStory(index: Int, coverImage: UIImage?, sourceView: UIView?, labelsContainerView: UIView?) -> ()
}

class StoryTableViewCell: UITableViewCell {
    
    class func reuseIdentifier() -> String {
        return NSStringFromClass(StoryTableViewCell.self).components(separatedBy: ".").last!
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var datesLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.setLineHeight(titleLabel.font.pointSize)
        }
    }
    var dates: String? { didSet { datesLabel.text = dates } }
    var localIdentifier: String?
    var storyIndex: Int?
    
    weak var delegate: StoryTableViewCellDelegate?
    
    @IBAction func tappedStory(_ sender: UIButton) {
        guard let storyIndex = storyIndex else {
            fatalError("Story index not set")
        }
        delegate?.didTapOnStory(index: storyIndex, coverImage: coverImageView.image, sourceView: coverImageView.superview, labelsContainerView: titleLabel.superview)
    }
    
    override func prepareForReuse() {
        coverImageView.image = nil
    }
    
}
