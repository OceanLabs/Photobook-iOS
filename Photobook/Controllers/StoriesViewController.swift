//
//  StoriesViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class StoriesViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    private var stories = [Story]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        StoriesManager.shared.topStories(10) { [weak welf = self] (stories) in
            // TODO: Handle permissions error
            guard let stories = stories else { return }
            welf?.stories = stories
            welf?.tableView.reloadData()
        }
    }
}

extension StoriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.row == 1 {
//            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier, for: indexPath) as! DoubleStoryTableViewCell
//            doubleCell.leftStoryViewModel = StoryViewModel(title: "DOUBLE THE LEFT TROUBLE", dates: "NOVEMBER 17", image: UIImage())
//            doubleCell.rightStoryViewModel = StoryViewModel(title: "DOUBLE THE RIGHT TROUBLE", dates: "DECEMBER 17", image: UIImage())
//            return doubleCell
//        }
        
        let story = stories[indexPath.row]
        
        let singleCell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier(), for: indexPath) as! StoryTableViewCell
        singleCell.title = story.title
        singleCell.dates = story.subtitle
        
        // TODO: Add check for localizedIndenfier
        StoriesManager.shared.thumbnailForPhoto(story.cover, size: singleCell.coverSize) { (image) in
            singleCell.cover = image
        }

        return singleCell
    }
}
