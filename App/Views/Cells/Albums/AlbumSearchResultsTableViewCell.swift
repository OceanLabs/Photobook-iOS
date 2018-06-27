//
//  AlbumSearchResultsTableViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AlbumSearchResultsTableViewCell: UITableViewCell {

    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    var albumId: String?

}
