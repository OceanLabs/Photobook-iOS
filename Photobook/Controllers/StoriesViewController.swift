//
//  StoriesViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class StoriesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension StoriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1 {
            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier, for: indexPath) as! DoubleStoryTableViewCell
            doubleCell.leftStoryViewModel = StoryViewModel(title: "Double the Left Trouble", dates: "November 17", image: UIImage())
            doubleCell.rightStoryViewModel = StoryViewModel(title: "Double the Right Trouble", dates: "December 17", image: UIImage())
            return doubleCell
        }
        
        let singleCell = tableView.dequeueReusableCell(withIdentifier: SingleStoryTableViewCell.reuseIdentifier, for: indexPath) as! SingleStoryTableViewCell
        singleCell.storyViewModel = StoryViewModel(title: "Single Trouble", dates: "September 17", image: UIImage())
        return singleCell
    }
}

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
            leftTitleLabel.text = leftStoryViewModel?.title
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


struct StoryViewModel {
    let title: String
    let dates: String
    let image: UIImage
}

class PhotoBookNavigationBar: UINavigationBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        barTintColor = .white
        shadowImage = UIImage()
    }

}
