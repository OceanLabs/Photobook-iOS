//
//  LayoutSelectionViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 13/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol LayoutSelectionViewControllerDelegate: class {
    
    func didSelectLayout(_ layout: Layout)
    
}

class LayoutSelectionViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.backgroundView = nil
            collectionView.backgroundColor = .clear
        }
    }
    
    var layouts: [Layout]! {
        didSet {
            collectionView?.reloadData()
        }
    }
    var selectedLayoutId: Int = 0
    
    weak var delegate: LayoutSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension LayoutSelectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layouts != nil ? 1 : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LayoutSelectionCollectionViewCell.reuseIdentifier, for: indexPath) as! LayoutSelectionCollectionViewCell
        cell.backgroundColor = .white
        cell.layoutNumberLabel.text = "\(indexPath.row + 1)"
        return cell
    }
}

extension LayoutSelectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let layout = layouts[indexPath.row]
        delegate?.didSelectLayout(layout)
    }
}

class LayoutSelectionCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(LayoutSelectionCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet weak var layoutNumberLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
}


