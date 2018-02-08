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
    func didTapOnStory(index: Int, sourceView: UIView?) -> ()
}

class StoryTableViewCell: UITableViewCell {
    
    class func reuseIdentifier() -> String {
        return NSStringFromClass(StoryTableViewCell.self).components(separatedBy: ".").last!
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var datesLabel: UILabel!
    @IBOutlet private weak var coverImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.setLineHeight(titleLabel.font.pointSize)
        }
    }
    var dates: String? { didSet { datesLabel.text = dates } }
    var cover: UIImage? { didSet { coverImageView.image = cover} }
    var localIdentifier: String?
    var storyIndex: Int?
    
    weak var delegate: StoryTableViewCellDelegate?
    
    lazy var coverSize = {
        return self.coverImageView.bounds.size
    }()
    
    @IBAction func tappedStory(_ sender: UIButton) {
        guard let storyIndex = storyIndex else {
            fatalError("Story index not set")
        }
        delegate?.didTapOnStory(index: storyIndex, sourceView: coverImageView.superview)
    }
    
}
