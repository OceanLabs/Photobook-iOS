//
//  ImageCollectorViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

protocol ImageCollectorViewControllerDelegate : class {
    func imageCollectorViewController(_ imageCollectorViewController:ImageCollectorViewController, didChangeHiddenStateTo hidden:Bool)
    func imageCollectorViewController(_ imageCollectorViewController:ImageCollectorViewController, didFinishWithAssets:[Asset])
}

class ImageCollectorViewController: UIViewController {
    
    public let requiredPhotosCount:Int = 15
    public var delegate:ImageCollectorViewControllerDelegate?
    
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var pickMoreLabel: UILabel!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var useTheseButtonContainer: UIView!
    @IBOutlet weak var useTheseCountView: UILabel!
    @IBOutlet weak var deleteDoneButton: UIButton!
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    private var selectedAssetsManager:SelectedAssetsManager?
    private var assets:[Asset] {
        get {
            if let manager = selectedAssetsManager {
                return manager.selectedAssets
            }
            return [Asset]()
        }
    }
    
    private let viewHeightDefault: CGFloat = 125
    private(set) var viewHeight:CGFloat = 0
    
    var isDeletingEnabled:Bool = false {
        didSet {
            if oldValue != isDeletingEnabled {
                deleteDoneButton.isHidden = !isDeletingEnabled
                useTheseButtonContainer.isHidden = isDeletingEnabled
                pickMoreLabel.isHidden = isDeletingEnabled
                longPressGestureRecognizer?.isEnabled = !isDeletingEnabled
            }
        }
    }
    private var isHideShowAnimated: Bool = false
    var isHidden:Bool = false {
        didSet {
            if oldValue != isHidden {
                viewHeight = isHidden ? 0 : viewHeightDefault
                let duration : TimeInterval = isHideShowAnimated ? 0.2 : 0
                UIView.animate(withDuration: duration, delay: 0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
                    self.topContainerView.isHidden = self.isHidden
                    self.imageCollectionView.isHidden = self.isHidden
                    self.adaptToParent()
                }, completion: { (completed) in
                    
                })
                delegate?.imageCollectorViewController(self, didChangeHiddenStateTo: isHidden)
            }
        }
    }
    
    private var horizontalConstraints:[NSLayoutConstraint]?
    private var verticalConstraints:[NSLayoutConstraint]?
    
    //only set once
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
    
    public static func instance(fromStoryboardWithParent parent:UIViewController, selectedAssetsManager:SelectedAssetsManager) -> ImageCollectorViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImageCollectorViewController") as! ImageCollectorViewController
        vc.parentController = parent
        vc.selectedAssetsManager = selectedAssetsManager
        return vc
    }
    
    //MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isHideShowAnimated = false //disable animation for this hidden state change
        isHidden = true
        
        //listen to asset manager
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerAddedAsset(_:)), name: SelectedAssetsManager.notificationNameSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerDeletedAsset(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCleared(_:)), name: SelectedAssetsManager.notificationNameCleared, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isHideShowAnimated = true //enable animation for hidden state changes
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = true
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = false
    }
    
    //MARK: - API
    
    @IBAction public func clearAssets() {
        selectedAssetsManager?.deselectAllAssets()
    }
    
    @objc private func assetCountChanged() {
        adaptToNewAssetCount()
    }
    
    @IBAction private func turnOnDeletingMode() {
        isDeletingEnabled = true
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }
    
    @IBAction private func turnOffDeletingMode() {
        isDeletingEnabled = false
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }
    
    @IBAction public func useThese() {
        delegate?.imageCollectorViewController(self, didFinishWithAssets: assets)
    }
    
    private func adaptToParent() {
        guard let parentController = parentController else {
            fatalError("ImageCollectorViewController not added to parent!")
        }
        
        view.frame = parentController.view.bounds
        
        if parent == nil {
            parentController.view.addSubview(view)
            parentController.addChildViewController(self)
            didMove(toParentViewController: parentController)
        }
        
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let vConstraints = verticalConstraints {
            view.superview?.removeConstraints(vConstraints)
        }
        if let hConstraints = horizontalConstraints {
            view.superview?.removeConstraints(hConstraints)
        }
        
        let viewDictionary : [ String : UIView ] = [ "collectorView" : view ]
        var height:Int = Int(viewHeight)
        if let tabBar = tabBar {
            height = height + Int(tabBar.frame.size.height)
        }
        
        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectorView]|", options: [], metrics: nil, views: viewDictionary)
        verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[collectorView(\(height))]|", options: [], metrics: nil, views: viewDictionary)
        
        view.superview?.addConstraints(horizontalConstraints! + verticalConstraints!)
        view.superview?.layoutIfNeeded()

    }
    
    private func adaptToNewAssetCount() {
        if assets.count == 0 {
            isHidden = true
            return
        } else {
            isHidden = false
        }
        
        if !isDeletingEnabled {
            if assets.count >= requiredPhotosCount {
                useTheseButtonContainer.isHidden = false
                pickMoreLabel.isHidden = true
                useTheseCountView.text = "\(assets.count)"
            } else {
                useTheseButtonContainer.isHidden = true
                pickMoreLabel.isHidden = false
                let pickMoreText = NSLocalizedString("Controllers/ImageCollectionViewController/PickMoreLabel",
                                                     value: "Pick another %@",
                                                     comment: "Amount of additionally selected photos required to build a photobook")
                pickMoreLabel.text = String(format: pickMoreText, "\(requiredPhotosCount-assets.count)")
            }
        }
        
        if assets.count > 0 {
            let indexPath = IndexPath(item: assets.count-1, section: 0)
            imageCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.right, animated: true)
        }
    }
    
    @objc private func selectedAssetManagerAddedAsset(_ notification: NSNotification) {
        if let index = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyIndex] as? Int {
            isDeletingEnabled = false
            imageCollectionView.insertItems(at: [IndexPath(row: index, section: 0)])
            var indexPaths = [IndexPath]()
            var i = 0
            while i<index {
                indexPaths.append(IndexPath(item: i, section: 0))
                i = i+1
            }
            imageCollectionView.reloadItems(at: indexPaths)
            adaptToNewAssetCount()
        }
    }
    
    @objc private func selectedAssetManagerDeletedAsset(_ notification: NSNotification) {
        if let index = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyIndex] as? Int {
            imageCollectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
            adaptToNewAssetCount()
        }
    }
    
    @objc private func selectedAssetManagerCleared(_ notification: NSNotification) {
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }

}

//MARK: - Collection View

extension ImageCollectorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectorCollectionViewCell", for: indexPath) as! ImageCollectorCollectionViewCell
        
        let asset = assets[indexPath.row]
        asset.image(size: cell.imageView.frame.size, completionHandler: { (image, error) in
            cell.imageView.image = image
        })
        cell.isDeletingEnabled = isDeletingEnabled
        print("cell deleting enabled: \(cell.isDeletingEnabled)")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if isDeletingEnabled {
            //remove
            selectedAssetsManager?.deselect(assets[indexPath.row])
        }
    }
    
}

extension ImageCollectorViewController : UIGestureRecognizerDelegate {
    
}
