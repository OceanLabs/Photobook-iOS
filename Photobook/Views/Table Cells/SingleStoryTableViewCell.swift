//
//  SingleStoryTableViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class SingleStoryTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = NSStringFromClass(SingleStoryTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var datesLabel: UILabel!
    @IBOutlet private weak var coverImageView: UIImageView!
    
    var storyViewModel: StoryViewModel? {
        didSet {
            titleLabel.text = storyViewModel?.title
            datesLabel.text = storyViewModel?.dates
            coverImageView.image = storyViewModel?.image
        }
    }
}

struct StoryViewModel {
    let title: String
    let dates: String
    let image: UIImage
}
