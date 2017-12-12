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
        static let maxStoriesToDisplay = 16
        static let viewStorySegueName = "ViewStorySegue"
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var stories = [Story]()
    private let selectedAssetsManager = SelectedAssetsManager()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStories()
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueName = segue.identifier else { return }
        switch segueName {
        case Constants.viewStorySegueName:
            guard let assetPickerController = segue.destination as? AssetPickerCollectionViewController,
                let segue = segue as? ViewStorySegue,
                let sender = sender as? (index: Int, sourceView: UIView?),
                let sourceView = sender.sourceView,
                let asset = stories[sender.index].assets.first
                else { return }
            assetPickerController.album = stories[sender.index]
            assetPickerController.selectedAssetsManager = selectedAssetsManager
            
            segue.asset = asset
            segue.sourceView = sourceView
        default:
            break
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadStories), name: .UIApplicationDidBecomeActive, object: nil)
    }

    @objc private func loadStories() {
        StoriesManager.shared.topStories(Constants.maxStoriesToDisplay) { [weak welf = self] (stories) in
            // TODO: Handle permissions error
            guard let stories = stories else { return }
            
            if stories.count == 0 {
                let title = NSLocalizedString("NoStoriesFound", value: "No Stories Found", comment: "Title shown to the user if the Photos app doesn't have any memory collections available")
                let message = NSLocalizedString("YourPhotosApp", value: "You don't seem to have any stories yet!\nGet out there and take more photos.", comment: "Message shown to the user if the Photos app doesn't have any memory collections available")
                welf?.emptyScreenViewController.show(message: message, title: title)
                return
            }
            
            welf?.stories = stories
            welf?.tableView.reloadData()

            // Once we are done loading the things needed to show on this screen, load the assets from each story so that they are ready if the user taps on a story
            for story in stories{
                story.loadAssets(completionHandler: nil)
            }
            
            welf?.emptyScreenViewController.hide(animated: true)
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
            isDouble = stories.count >= (indexPath.row * 2) // Check if we have enought stories for a double cell
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
            doubleCell.localIdentifier = story.identifier
            doubleCell.storyIndex = storyIndex
            doubleCell.delegate = self
            
            story.coverImage(size: doubleCell.coverSize, completionHandler:{ (image, _) in
                if doubleCell.localIdentifier == story.identifier {
                    doubleCell.cover = image
                }
            })
            secondStory.coverImage(size: doubleCell.coverSize, completionHandler: { (image, _) in
                if doubleCell.localIdentifier == story.identifier {
                    doubleCell.secondCover = image
                }
            })
            
            return doubleCell
        }
        
        let story = stories[storyIndex]

        let singleCell = tableView.dequeueReusableCell(withIdentifier: StoryTableViewCell.reuseIdentifier(), for: indexPath) as! StoryTableViewCell
        singleCell.title = story.title
        singleCell.dates = story.subtitle
        singleCell.localIdentifier = story.identifier
        singleCell.storyIndex = storyIndex
        singleCell.delegate = self

        story.coverImage(size: singleCell.coverSize, completionHandler: { (image, _) in
            if singleCell.localIdentifier == story.identifier {
                singleCell.cover = image
            }
        })

        return singleCell
    }
}

extension StoriesViewController: StoryTableViewCellDelegate {
    func didTapOnStory(index: Int, sourceView: UIView?) {
        performSegue(withIdentifier: Constants.viewStorySegueName, sender: (index: index, sourceView: sourceView))
    }
}
