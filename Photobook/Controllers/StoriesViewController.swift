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
}

extension StoriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1 {
            let doubleCell = tableView.dequeueReusableCell(withIdentifier: DoubleStoryTableViewCell.reuseIdentifier, for: indexPath) as! DoubleStoryTableViewCell
            doubleCell.leftStoryViewModel = StoryViewModel(title: "DOUBLE THE LEFT TROUBLE", dates: "NOVEMBER 17", image: UIImage())
            doubleCell.rightStoryViewModel = StoryViewModel(title: "DOUBLE THE RIGHT TROUBLE", dates: "DECEMBER 17", image: UIImage())
            return doubleCell
        }
        
        let singleCell = tableView.dequeueReusableCell(withIdentifier: SingleStoryTableViewCell.reuseIdentifier, for: indexPath) as! SingleStoryTableViewCell
        singleCell.storyViewModel = StoryViewModel(title: "SINGLE TROUBLE", dates: "SEPTEMBER 17", image: UIImage())
        return singleCell
    }
}
