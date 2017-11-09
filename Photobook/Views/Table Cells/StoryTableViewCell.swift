//
//  StoryTableViewCell.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class StoryTableViewCell: UITableViewCell {
    
    class func reuseIdentifier() -> String {
        return NSStringFromClass(StoryTableViewCell.self).components(separatedBy: ".").last!
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var datesLabel: UILabel!
    @IBOutlet private weak var coverImageView: UIImageView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.setLineHeight(48.0)
        }
    }
    var dates: String? { didSet { datesLabel.text = dates } }
    var cover: UIImage? { didSet { coverImageView.image = cover} }
    
    lazy var coverSize = {
        return self.coverImageView.bounds.size
    }()
}
