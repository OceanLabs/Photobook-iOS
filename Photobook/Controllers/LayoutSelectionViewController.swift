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

    private struct Constants {
        static let pageSideMargin: CGFloat = 20.0
    }

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.backgroundView = nil
            collectionView.backgroundColor = .clear
        }
    }
    
    private var pageSize: CGSize = .zero
    private var image: UIImage?
    
    var pageIndex: Int!
    var pageType: PageType!
    var pageSizeRatio: CGFloat! {
        didSet {
            let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let pageWidth = flowLayout.itemSize.width - Constants.pageSideMargin
            let pageHeight = pageWidth / pageSizeRatio
            pageSize = CGSize(width: pageWidth, height: pageHeight)
        }
    }
    var asset: Asset? {
        didSet {
            guard let asset = asset else { return }
            
            let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            asset.image(size: flowLayout.itemSize, completionHandler: { (image, error) in
                guard error == nil else {
                    print("Layouts: error retrieving image")
                    return
                }
                self.image = image
                self.collectionView?.reloadData()
            })
        }
    }
    var layouts: [Layout]! {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var selectedLayoutIndex = 0
    var selectedLayout: Layout! {
        didSet {
            self.selectedLayoutIndex = self.layouts.index(of: selectedLayout) ?? 0
            self.collectionView.scrollToItem(at: IndexPath(row: selectedLayoutIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    weak var delegate: LayoutSelectionViewControllerDelegate?
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

        cell.pageIndex = pageIndex
        cell.layout = layouts[indexPath.row]
        cell.aspectRatio = pageSizeRatio
        cell.image = image // Pass the image to avoid reloading
        cell.asset = asset
        cell.pageType = pageType
        cell.isBorderVisible = (indexPath.row == selectedLayoutIndex)
        cell.setupLayout()

        return cell
    }
}

extension LayoutSelectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let layout = layouts[indexPath.row]
        selectedLayoutIndex = indexPath.row
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(row: selectedLayoutIndex, section: 0), at: .centeredHorizontally, animated: true)
        delegate?.didSelectLayout(layout)
    }
}
