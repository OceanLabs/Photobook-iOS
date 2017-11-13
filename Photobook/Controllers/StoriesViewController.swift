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
        static let storiesInHeader = 6
        static let rowsInHeader = 4
        static let storiesPerLayoutPattern = 3
        static let rowsPerLayoutPattern = 2
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

        if stories.count <= Constants.storiesInHeader {
            switch stories.count {
            case 1, 2: return stories.count
            case 3, 4: return Constants.rowsInHeader - 1
            case 5, 6: return Constants.rowsInHeader
            default: return 0
            }
        } else {
            let withoutHeadStories = stories.count - Constants.storiesInHeader
            let baseOffset = withoutHeadStories / Constants.storiesPerLayoutPattern
            let repeatedLayoutIndex = withoutHeadStories % Constants.rowsPerLayoutPattern
            return baseOffset * Constants.rowsPerLayoutPattern + (repeatedLayoutIndex == 0 ? 1 : 2) + Constants.rowsInHeader
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var isDouble = false
        var storyIndex = 0
        
        switch indexPath.row {
        case 0, 1: // Single cells for the first and second rows
            storyIndex = indexPath.row
        case 2, 3: // Double cells for the second and third rows
            storyIndex = indexPath.row == 2 ? 2 : 4 // Indexes corresponding to the first story of the third and fourth rows
            isDouble = true
        default:
            let minusHeaderRows = indexPath.row - Constants.rowsInHeader
            let numberOfLayouts = minusHeaderRows / Constants.rowsPerLayoutPattern
            let potentialDouble = minusHeaderRows % Constants.rowsPerLayoutPattern == 1 // First row in the layout pattern is a single & the second a double
            
            storyIndex = numberOfLayouts * Constants.storiesPerLayoutPattern + (potentialDouble ? 1 : 0) + Constants.storiesInHeader
            isDouble = (potentialDouble && storyIndex < stories.count - 1)
        }
        
        if isDouble {
            // Double cell
            let story = stories[storyIndex]
            let secondStory = stories[storyIndex + 1]
            
            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier(), for: indexPath) as! DoubleStoryTableViewCell
            doubleCell.title = story.title
            doubleCell.dates = story.subtitle
            doubleCell.secondTitle = secondStory.title
            doubleCell.secondDates = secondStory.subtitle
            doubleCell.localIdentifier = story.cover.localIdentifier
            
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
        }
        
        let story = stories[storyIndex]

        let singleCell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier(), for: indexPath) as! StoryTableViewCell
        singleCell.title = story.title
        singleCell.dates = story.subtitle
        singleCell.localIdentifier = story.cover.localIdentifier

        StoriesManager.shared.thumbnailForPhoto(story.cover, size: singleCell.coverSize) { (image) in
            if singleCell.localIdentifier == story.cover.localIdentifier {
                singleCell.cover = image
            }
        }

        return singleCell
    }
}
