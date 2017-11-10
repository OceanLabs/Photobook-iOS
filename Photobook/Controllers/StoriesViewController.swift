//
//  StoriesViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class StoriesViewController: UIViewController {

    private struct Constants {
        static let rowsPerBatch = 4
        static let storiesPerBatch = 6
        static let thirdLayoutRow = 2
        static let fourthLayoutRow = 3
        static let firstThirdRowStory = 3
        static let firstFourthRowStory = 5
    }
    
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
        let batches = stories.count / Constants.storiesPerBatch  // Number of sets of story layouts
        let extra = stories.count % Constants.storiesPerBatch  // Stories that don't make up a full layout
        
        var rows = Constants.rowsPerBatch * batches // Number of rows for full batches
        
        // Calculate the additional rows for the extra stories
        if extra <= 2 { rows += extra }     // First two stories go in single cells
        else { rows += 3 }  // If we have 3 or 4 stories, then we need 3 extra cells (1-1-2)
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let masterIndex = indexPath.row % Constants.rowsPerBatch // Determine the index in the layout design (0-3)
        let storyBaseOffset = (indexPath.row / Constants.rowsPerBatch) * Constants.storiesPerBatch // All rows before this layout instance
        
        var storyIndex = 0
        
        switch masterIndex {
        case Constants.thirdLayoutRow where stories.count > storyBaseOffset + Constants.firstThirdRowStory:
            storyIndex = storyBaseOffset + masterIndex
            fallthrough
        case Constants.fourthLayoutRow where stories.count > storyBaseOffset + Constants.firstFourthRowStory:
            if storyIndex == 0 {
                storyIndex = storyBaseOffset + masterIndex + 1 // Add one to the offset because the third row has 2 stories
            }
            // Double cell
            let story = stories[storyIndex]
            let secondStory = stories[storyIndex + 1]
            
            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier(), for: indexPath) as! DoubleStoryTableViewCell
            doubleCell.title = story.title
            doubleCell.dates = story.subtitle
            doubleCell.secondTitle = secondStory.title
            doubleCell.secondDates = secondStory.subtitle
            doubleCell.localIdentifier = story.cover.localIdentifier
            
            // TODO: Add check for localizedIndenfier
            StoriesManager.shared.thumbnailForPhoto(story.cover, size: doubleCell.coverSize) { (image) in
                if doubleCell.localIdentifier == story.cover.localIdentifier {
                    doubleCell.cover = image
                }
            }
            StoriesManager.shared.thumbnailForPhoto(secondStory.cover, size: doubleCell.coverSize) { (image) in
                if doubleCell.localIdentifier == story.cover.localIdentifier {
                    doubleCell.secondCover = image
                }
            }
            
            return doubleCell
        default:
            // Single cell
            storyIndex = storyBaseOffset + masterIndex
            let story = stories[storyIndex]
            
            let singleCell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier(), for: indexPath) as! StoryTableViewCell
            singleCell.title = story.title
            singleCell.dates = story.subtitle
            singleCell.localIdentifier = story.cover.localIdentifier
            
            // TODO: Add check for localizedIndenfier
            StoriesManager.shared.thumbnailForPhoto(story.cover, size: singleCell.coverSize) { (image) in
                if singleCell.localIdentifier == story.cover.localIdentifier {
                    singleCell.cover = image
                }
            }
            
            return singleCell
        }
    }
}
