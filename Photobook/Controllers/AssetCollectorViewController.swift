//
//  AssetCollectorViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

protocol AssetCollectorViewControllerDelegate : class {
    func assetCollectorViewController(_ assetCollectorViewController: AssetCollectorViewController, didChangeHiddenStateTo hidden: Bool)
    func assetCollectorViewController(_ assetCollectorViewController: AssetCollectorViewController, didFinishWithAssets: [Asset])
}

class AssetCollectorViewController: UIViewController {
    
    public var delegate: AssetCollectorViewControllerDelegate?
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var clearButton: UIButton!
    @IBOutlet private weak var pickMoreLabel: UILabel!
    @IBOutlet private weak var imageCollectionView: UICollectionView!
    @IBOutlet private weak var useTheseButtonContainer: UIView!
    @IBOutlet private weak var useTheseCountView: UILabel!
    @IBOutlet private weak var deleteDoneButton: UIButton!
    
    @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    private var selectedAssetsManager: SelectedAssetsManager! {
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: SelectedAssetsManager.notificationNameSelected, object: oldValue)
                NotificationCenter.default.removeObserver(self, name: SelectedAssetsManager.notificationNameDeselected, object: oldValue)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerAddedAsset(_:)), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
            NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerDeletedAsset(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
        }
    }
    private var assets: [Asset] {
        get {
            if let manager = selectedAssetsManager {
                return manager.selectedAssets
            }
            return [Asset]()
        }
    }
    
    private let viewHeightDefault: CGFloat = 125
    private(set) var viewHeight: CGFloat = 0
    
    var isDeletingEnabled = false {
        didSet {
            if oldValue != isDeletingEnabled {
                deleteDoneButton.isHidden = !isDeletingEnabled
                useTheseButtonContainer.isHidden = isDeletingEnabled
                pickMoreLabel.isHidden = isDeletingEnabled
                longPressGestureRecognizer.isEnabled = !isDeletingEnabled
            }
        }
    }
    
    private var isHideShowAnimated: Bool = false
    public var isHidden: Bool = false {
        didSet {
            if oldValue != isHidden {
                viewHeight = isHidden ? 0 : viewHeightDefault
                let duration: TimeInterval = isHideShowAnimated ? 0.2 : 0
                let options = isHidden ? UIViewAnimationOptions.curveEaseIn : UIViewAnimationOptions.curveEaseOut
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    self.topContainerView.isHidden = self.isHidden
                    self.imageCollectionView.isHidden = self.isHidden
                    self.adaptHeight()
                }, completion: nil)
                delegate?.assetCollectorViewController(self, didChangeHiddenStateTo: isHidden)
            }
        }
    }
    
    private var horizontalConstraints: [NSLayoutConstraint]?
    private var verticalConstraints: [NSLayoutConstraint]?
    private var heightConstraint: NSLayoutConstraint?
    
    //only set once
    private weak var parentController: UIViewController? {
        didSet {
            if parentController != nil {
                adaptToParent()
            }
        }
    }
    
    private var tabBar: PhotobookTabBar? {
        get {
            var tabBar: UITabBar?
            if let tab = tabBarController {
                tabBar = tab.tabBar
            } else if let tab = self.navigationController?.tabBarController {
                tabBar = tab.tabBar
            }
            return tabBar as? PhotobookTabBar
        }
    }
    
    public static func instance(fromStoryboardWithParent parent: UIViewController, selectedAssetsManager: SelectedAssetsManager) -> AssetCollectorViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImageCollectorViewController") as! AssetCollectorViewController
        vc.parentController = parent
        vc.selectedAssetsManager = selectedAssetsManager
        
        return vc
    }
    
    //MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isHideShowAnimated = false //disable animation for this hidden state change
        isHidden = true
        
        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isHideShowAnimated = false
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = true
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = true
        isHideShowAnimated = true //enable animation for hidden state changes
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //adapt tabbar
        tabBar?.isBackgroundHidden = false
        isHideShowAnimated = false
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
        self.delegate?.assetCollectorViewController(self, didFinishWithAssets: assets)
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
        
        let viewDictionary : [ String : UIView ] = [ "collectorView" : view ]
        if verticalConstraints == nil {
            verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[collectorView]|", options: [], metrics: nil, views: viewDictionary)
            view.superview?.addConstraints(verticalConstraints!)
        }
        if horizontalConstraints == nil {
            horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectorView]|", options: [], metrics: nil, views: viewDictionary)
            view.superview?.addConstraints(horizontalConstraints!)
        }
        view.superview?.layoutIfNeeded()
        
        adaptHeight()
    }
    
    private func adaptHeight() {
        var height: CGFloat = viewHeight
        if let tabBar = tabBar {
            height = height + tabBar.frame.size.height
        }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if heightConstraint == nil {
            //create new contraint
            heightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
            view.addConstraint(heightConstraint!)
        }
        
        //set constraint value
        heightConstraint?.constant = height
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func adaptToNewAssetCount() {
        if assets.count == 0 {
            isHidden = true
            return
        }
        isHidden = false
        
        if !isDeletingEnabled {
            let requiredPhotosCount = ProductManager.shared.minimumRequiredAssets
            let fadeDuration: TimeInterval = 0.25
            if assets.count >= requiredPhotosCount {
                //use these
                let changesState = useTheseButtonContainer.isHidden == true || pickMoreLabel.isHidden == false
                useTheseButtonContainer.isHidden = false
                useTheseCountView.text = "\(assets.count)"
                
                //animate
                let duration: TimeInterval = changesState ? fadeDuration : 0
                useTheseButtonContainer.alpha = 0
                UIView.animate(withDuration: duration, animations: {
                    self.useTheseButtonContainer.alpha = 1
                    self.pickMoreLabel.alpha = 0
                }, completion: { (finished) in
                    self.pickMoreLabel.isHidden = true
                })
            } else {
                //pick more
                let changesState = useTheseButtonContainer.isHidden == false || pickMoreLabel.isHidden == true
                useTheseButtonContainer.isHidden = true
                pickMoreLabel.isHidden = false
                let pickMoreText = NSLocalizedString("Controllers/ImageCollectionViewController/PickMoreLabel",
                                                     value: "Pick another %@",
                                                     comment: "Amount of additionally selected photos required to build a photobook")
                pickMoreLabel.text = String(format: pickMoreText, "\(requiredPhotosCount-assets.count)")
                
                //animate
                let duration: TimeInterval = changesState ? fadeDuration : 0
                pickMoreLabel.alpha = 0
                UIView.animate(withDuration: duration, animations: {
                    self.pickMoreLabel.alpha = 1
                    self.useTheseButtonContainer.alpha = 0
                }, completion: { (finished) in
                    self.useTheseButtonContainer.isHidden = true
                })
            }
        }
    }
    
    private func moveToCollectionViewEnd() {
        if assets.count > 0 {
            let indexPath = IndexPath(item: assets.count-1, section: 0)
            imageCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.right, animated: true)
        }
    }
    
    @objc private func selectedAssetManagerAddedAsset(_ notification: NSNotification) {
        if let indices = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyIndices] as? [Int] {
            isDeletingEnabled = false
            var indexPaths = [IndexPath]()
            for index in indices {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            imageCollectionView.insertItems(at: indexPaths)
            indexPaths.removeAll()
            var i = 0
            while i<assets.count {
                if indices.index(where: { (x) -> Bool in
                    return x == i
                }) == nil {
                    indexPaths.append(IndexPath(item: i, section: 0))
                }
                i = i+1
            }
            imageCollectionView.reloadItems(at: indexPaths)
            adaptToNewAssetCount()
            moveToCollectionViewEnd()
        }
    }
    
    @objc private func selectedAssetManagerDeletedAsset(_ notification: NSNotification) {
        if let indices = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyIndices] as? [Int] {
            var indexPaths = [IndexPath]()
            for index in indices {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            
            self.imageCollectionView.deleteItems(at: indexPaths)
            self.adaptToNewAssetCount()
            
        }
    }
    
    @objc private func selectedAssetManagerCleared(_ notification: NSNotification) {
        imageCollectionView.reloadData()
        adaptToNewAssetCount()
    }
}

//MARK: - Collection View

extension AssetCollectorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectorCollectionViewCell", for: indexPath) as! AssetCollectorCollectionViewCell
        
        let asset = assets[indexPath.row]
        asset.image(size: cell.imageView.frame.size, completionHandler: { (image, error) in
            cell.imageView.image = image
        })
        cell.isDeletingEnabled = isDeletingEnabled
        
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

extension AssetCollectorViewController : UIGestureRecognizerDelegate {
    
}
