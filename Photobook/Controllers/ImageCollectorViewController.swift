//
//  ImageCollectorViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class ImageCollectorViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public let requiredPhotosCount:Int = 15
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var pickMoreLabel: UILabel!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var useTheseButtonContainer: UIView!
    
    @IBOutlet weak var useTheseCountView: UILabel!
    private var assets = [Asset]()
    
    private weak var parentController: UIViewController? {
        didSet {
            if parentController != nil {
                adaptToParent()
            }
        }
    }
    
    private var tabBar:PhotoBookTabBar? {
        get {
            var tabBar: UITabBar?
            if let tab = tabBarController {
                tabBar = tab.tabBar
            } else if let tab = self.navigationController?.tabBarController {
                tabBar = tab.tabBar
            }
            return tabBar as? PhotoBookTabBar
        }
    }
    
    public static func instance(fromStoryboardWithParent parent:UIViewController) -> ImageCollectorViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImageCollectorViewController") as! ImageCollectorViewController
        vc.parentController = parent
        return vc
    }
    
    //MARK: - API
    
    public func add(asset:Asset) {
        assets.append(asset)
        adaptToNewAssetCount()
    }
    
    public func remove(asset:Asset) {
        
    }
    
    public func getAssets() -> [Asset] {
        return assets
    }
    
    @IBAction public func clearAssets() {
        assets = [Asset]()
        adaptToNewAssetCount()
    }
    
    //MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: remove dis
        clearAssets()
        var i = 0
        while i<10 {
            add(asset: PhotosAsset(PHAsset()))
            i = i+1
        }
        adaptToNewAssetCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = false
    }
    
    private func adaptToParent() {
        guard let parentController = parentController else {
            fatalError("ImageCollectorViewController not added to parent!")
        }
    
        //clear previous context
        view.removeFromSuperview()
        removeFromParentViewController()
        
        view.frame = parentController.view.bounds
        
        if parent == nil {
            parentController.view.addSubview(view)
            parentController.addChildViewController(self)
            didMove(toParentViewController: parentController)
        }
        
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let viewDictionary : [ String : UIView ] = [ "collectorView" : view ]
        var viewHeight:Int = 125
        if let tabBar = tabBar {
            viewHeight = viewHeight + Int(tabBar.frame.size.height)
        }
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectorView]|", options: [], metrics: nil, views: viewDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[collectorView(\(viewHeight))]|", options: [], metrics: nil, views: viewDictionary)
        
        view.superview?.addConstraints(horizontalConstraints + verticalConstraints)
        view.superview?.layoutIfNeeded()
    }
    
    private func adaptToNewAssetCount() {
        if assets.count >= requiredPhotosCount {
            useTheseButtonContainer.isHidden = false
            pickMoreLabel.isHidden = true
        } else {
            useTheseButtonContainer.isHidden = true
            pickMoreLabel.isHidden = false
            let pickMoreText = NSLocalizedString("Controllers/ImageCollectionViewController/PickMoreLabel",
                                              value: "Pick another %@",
                                              comment: "Amount of additionally selected photos required to build a photobook")
            pickMoreLabel.text = String(format: pickMoreText, "\(requiredPhotosCount-assets.count)")
        }
        imageCollectionView.reloadData()
    }

    //MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectorCollectionViewCell", for: indexPath) as! ImageCollectorCollectionViewCell
        
        return cell
    }
}
