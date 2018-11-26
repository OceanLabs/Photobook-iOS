//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Photobook

protocol AssetPickerCollectionViewControllerDelegate: class {
    func viewControllerForPresentingOn() -> UIViewController?
}

class AssetPickerCollectionViewController: UICollectionViewController {
    
    private struct Constants {
        static let loadingCellReuseIdentifier = "LoadingCell"
        static let marginBetweenImages: CGFloat = 1
        static let numberOfCellsPerRow: CGFloat = 4 //CGFloat because it's used in size calculations
        static let numberOfAssetPlaceholders = 50
    }

    @IBOutlet private weak var selectAllButton: UIBarButtonItem?
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    weak var delegate: AssetPickerCollectionViewControllerDelegate?
    
    private var previousPreheatRect = CGRect.zero
    
    var selectedAssetsManager: SelectedAssetsManager?
    private var accountManager: AccountClient?
    private var assetCollectorController: AssetCollectorViewController!
    
    var delayCollectorAppearance = false
    
    static let coverAspectRatio: CGFloat = 2.723684211
    
    private lazy var imageCellSize: CGSize = {
        guard let collectionView = collectionView else { return .zero }
        var usableSpace = collectionView.frame.width
        usableSpace -= (Constants.numberOfCellsPerRow - 1.0) * Constants.marginBetweenImages
        let cellWidth = usableSpace / Constants.numberOfCellsPerRow
        return CGSize(width: cellWidth, height: cellWidth)
    }()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    var albumManager: AlbumManager?
    var album: Album! {
        didSet{
            self.title = album.localizedName
        }
    }
    
    var collectorMode: AssetCollectorMode = .selecting
    weak var addingDelegate: PhotobookAssetAddingDelegate?
    
    var shouldAnimateAssetPicker = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pickerAnalytics = album as? PickerAnalytics {
            let screenName = collectorMode == .selecting ? pickerAnalytics.selectingPhotosScreenName : pickerAnalytics.addingMorePhotosScreenName
            Analytics.shared.trackScreenViewed(screenName)
        }
        
        resetCachedAssets()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        registerFor3DTouch()
        
        // Listen to asset manager
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
        
        // Listen for album changes
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereUpdated(_:)), name: AlbumManagerNotificationName.albumsWereUpdated, object: nil)
    }
    
    private func loadAssets() {
        guard album.assets.isEmpty else {
            postAlbumLoadSetup()
            return
        }

        activityIndicator.startAnimating()

        album.loadAssets(completionHandler: { [weak welf = self] error in
            welf?.postAlbumLoadSetup()
            
            guard error == nil else {
                welf?.showErrorMessage(error: error!) { welf?.loadAssets() }
                return
            }

            welf?.collectionView?.reloadData()
            welf?.resetCachedAssets()
        })
    }
    
    private func postAlbumLoadSetup() {
        activityIndicator.stopAnimating()
        
        updateSelectAllButton()
    }

    private func showErrorMessage(error: Error, dismissAfter: TimeInterval? = nil, completion: (() -> Void)?) {
        let message: ErrorMessage
        var offsetTop: CGFloat = 0.0
        
        if let error = error as? AccountError {
            switch error {
            case .notLoggedIn:
                self.accountManager?.logout()
                self.popToLandingScreen()
            }
            return
        }

        // If the message requires an action, use the empty screen
        if let errorMessage = error as? ActionableErrorMessage {
            var errorCopy = errorMessage
            errorCopy.buttonAction = {
                errorMessage.buttonAction()
                if errorMessage.dismissErrorPromptAfterAction {
                    self.emptyScreenViewController.hide()
                }
            }
            emptyScreenViewController.show(errorCopy)
            return
        }
        
        if let error = error as? ErrorMessage {
            message = error
        } else {
            message = ErrorMessage(error)
        }
        
        // Adding assets: the album picker will be presented modally inside a navigation controller
        if let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar {
            offsetTop = navigationBar.barHeight
        }
        
        MessageBarViewController.show(message: message, parentViewController: self, offsetTop: offsetTop, centred: true, dismissAfter: dismissAfter) {
            completion?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadAssets()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !delayCollectorAppearance {
            setupCollector()
        }
    }
    
    func setupCollector() {
        // Setup the Asset Collector Controller
        if assetCollectorController == nil, let manager = selectedAssetsManager {
            assetCollectorController = AssetCollectorViewController.instance(fromStoryboardWithParent: self, selectedAssetsManager: manager, delayAppearance: delayCollectorAppearance)
            assetCollectorController.mode = collectorMode
            assetCollectorController.delegate = self
        }
    }
    
    func registerFor3DTouch() {
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: collectionView!)
        }
    }
    
    @objc func albumsWereUpdated(_ notification: Notification) {
        guard let collectionView = self.collectionView,
            let albumsChanges = notification.object as? [AlbumChange]
            else { return }
        
        for albumChange in albumsChanges {
            if albumChange.albumIdentifier == self.album.identifier {
                var indexPathsInserted = [IndexPath]()
                for assetInserted in albumChange.assetsInserted {
                    if let index = self.album.assets.index(where: { $0.identifier == assetInserted.identifier }) {
                        indexPathsInserted.append(IndexPath(item: index, section: 0))
                    }
                }
                
                var indexPathsRemoved = [IndexPath]()
                for indexRemoved in albumChange.indexesRemoved {
                    indexPathsRemoved.append(IndexPath(item: indexRemoved, section: 0))
                }
                
                collectionView.performBatchUpdates({
                    collectionView.deleteItems(at: indexPathsRemoved)
                    collectionView.insertItems(at: indexPathsInserted)
                    collectionView.reloadSections(IndexSet(integer: 1))
                }, completion: nil)
                
                break
            }
        }
    }
    
    @IBAction func unwindToThisView(withUnwindSegue unwindSegue: UIStoryboardSegue) {}

    @IBAction func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        guard !(sender.title?.isEmpty ?? true) else { return }
        
        if selectedAssetsManager?.count(for: album) == album.assets.count {
            selectedAssetsManager?.deselectAllAssets(for: album)
            Analytics.shared.trackAction(.pickerDeselectAllTapped)
        }
        else {
            selectedAssetsManager?.selectAllAssets(for: album)
            Analytics.shared.trackAction(.pickerSelectAllTapped)
        }
        
        updateSelectAllButton()
        
        for indexPath in collectionView?.indexPathsForVisibleItems ?? [] {
            updateSelectedStatus(indexPath: indexPath)
        }
    }
    
    func updateSelectAllButton() {
        // Hide "Select All" if current album has too many photos
        if selectedAssetsManager?.willSelectingAllExceedTotalAllowed(album) ?? false {
            selectAllButton?.title = nil
            return
        }
        
        updateSelectAllButtonTitle()
    }
    
    func updateSelectAllButtonTitle() {        
        if selectedAssetsManager?.count(for: album) == self.album.assets.count {
            selectAllButton?.title = NSLocalizedString("ImagePicker/Button/DeselectAll", value: "Deselect All", comment: "Button title for de-selecting all selected photos")
        }
        else {
            selectAllButton?.title = NSLocalizedString("ImagePicker/Button/SelectAll", value: "Select All", comment: "Button title for selecting all selected photos")
        }
    }
    
    private func updateSelectedStatus(cell: AssetPickerCollectionViewCell? = nil, indexPath: IndexPath, asset: PhotobookAsset? = nil) {
        guard let cell = cell ?? collectionView?.cellForItem(at: indexPath) as? AssetPickerCollectionViewCell else { return }
        let asset = asset ?? album.assets[indexPath.item]
        
        let selected = selectedAssetsManager?.isSelected(asset) ?? false
        cell.selectedStatusImageView.image = selected ? UIImage(named: "Tick") : UIImage(named: "Tick-empty")
    }
    
    func coverImageLabelsContainerView() -> UIView? {
        guard let cell = collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? AssetPickerCoverCollectionViewCell else { return nil }
        
        return cell.labelsContainerView
    }
    
    // MARK: UIScrollView
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    private func resetCachedAssets() {
        albumManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard let collectionView = collectionView,
            isViewLoaded,
            view.window != nil,
            !collectionView.visibleCells.isEmpty
            else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in album.assets[indexPath.item] }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in album.assets[indexPath.item] }
        
        // Update the assets the PHCachingImageManager is caching.
        albumManager?.startCachingImages(for: addedAssets,
                                        targetSize: imageCellSize)
        albumManager?.stopCachingImages(for: removedAssets,
                                       targetSize: imageCellSize)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    @objc private func selectedAssetManagerCountChanged(_ notification: NSNotification) {
        guard let assets = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyAssets] as? [PhotobookAsset] else {
            return
        }
        for asset in assets {
            if let index = album.assets.index(where: { (a) -> Bool in
                return a == asset
            }) {
                updateSelectedStatus(indexPath: IndexPath(row: index, section: 0), asset: asset)
            }
        }
        
        updateSelectAllButton()
    }
    
}

extension AssetPickerCollectionViewController: LogoutHandler {
    
    func prepareToHandleLogout(accountManager: AccountClient) {
        self.accountManager = accountManager
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Social/Logout", value: "Log Out", comment: "Button title for loggin out of social accounts, eg Facebook, Instagram"), style: .plain, target: self, action: #selector(confirmLogout))
    }
    
    @objc private func confirmLogout() {
        guard let accountManager = accountManager else { return }
        let alertController = UIAlertController(title: NSLocalizedString("Social/LogoutConfirmationAlertTitle", value: "Log Out", comment: "Alert title asking the user to log out of social service eg Instagram/Facebook"), message: NSLocalizedString("Social/LogoutConfirmationAlertMessage", value: "Are you sure you want to log out of \(accountManager.serviceName)?", comment: "Alert message asking the user to log out of social service eg Instagram/Facebook"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Alert/Yes", value: "Yes", comment: "Affirmative button title for alert asking the user confirmation for an action"), style: .default, handler: { _ in
            accountManager.logout()
            self.popToLandingScreen()
        }))
        
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func popToLandingScreen() {
        guard let accountManager = accountManager else { return }
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: accountManager.serviceName + "LandingViewController")
        self.navigationController?.setViewControllers([viewController, self], animated: false)
        self.navigationController?.popViewController(animated: true)
    }
}


extension AssetPickerCollectionViewController: AssetCollectorViewControllerDelegate {
    // MARK: AssetCollectorViewControllerDelegate
    
    func actionsForAssetCollectorViewControllerHiddenStateChange(_ assetCollectorViewController: AssetCollectorViewController, willChangeTo hidden: Bool) -> () -> () {
        return { [weak welf = self] in
            let topInset: CGFloat
            let bottomInset: CGFloat
            if #available(iOS 11, *){
                topInset = 0
                bottomInset = hidden ? 0 : assetCollectorViewController.viewHeight
            } else {
                topInset =  welf?.navigationController?.navigationBar.frame.maxY ?? 0
                bottomInset = assetCollectorViewController.view.frame.height - assetCollectorViewController.view.transform.ty
            }
            welf?.collectionView?.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        }
    }
    
    func assetCollectorViewControllerDidFinish(_ assetCollectorViewController: AssetCollectorViewController) {
        switch collectorMode {
        case .adding:
            addingDelegate?.didFinishAdding(selectedAssetsManager?.selectedAssets)
        default:
            let dataSourceBackup = AssetDataSourceBackup()
            dataSourceBackup.albumManager = albumManager
            dataSourceBackup.album = album
            AssetDataSourceBackupManager.shared.saveBackup(dataSourceBackup)

            if UserDefaults.standard.bool(forKey: hasShownTutorialKey) {
                if let viewController = photobookViewController() {
                    navigationController?.pushViewController(viewController, animated: true)
                }
            } else {
                guard let photobookViewController = self.photobookViewController() else { return }

                let completion = { [weak welf = self] in
                    UserDefaults.standard.set(true, forKey: hasShownTutorialKey)
                    
                    let tutorialViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TutorialViewController") as! TutorialViewController
                    tutorialViewController.completionClosure = { [weak welf = self] (viewController) in
                        welf?.dismiss(animated: true, completion: nil)
                    }
                    welf?.present(tutorialViewController, animated: true)
                }
            
                CATransaction.begin()
                CATransaction.setCompletionBlock(completion)
                self.navigationController?.pushViewController(photobookViewController, animated: true)
                CATransaction.commit()
            }
        }
        selectedAssetsManager?.orderAssetsByDate()
    }
    
    private func photobookViewController() -> UIViewController? {
        
        let photobookViewController = PhotobookSDK.shared.photobookViewController(with: selectedAssetsManager!.selectedAssets, embedInNavigation: false, navigatesToCheckout: false, delegate: self) {
            [weak welf = self] (viewController, success) in
            
            guard success else {
                AssetDataSourceBackupManager.shared.deleteBackup()
                
                if let tabBar = viewController.tabBarController?.tabBar {
                    tabBar.isHidden = false
                }
                
                viewController.navigationController?.popViewController(animated: true)
                return
            }

            let items = Checkout.shared.numberOfItemsInBasket()
            if items == 0 {
                Checkout.shared.addCurrentProductToBasket()
            } else {
                // Only allow one item in the basket
                Checkout.shared.clearBasketOrder()
                Checkout.shared.addCurrentProductToBasket(items: items)
            }
            
            // Photobook completion
            if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, dismissClosure: {
                [weak welf = self] (viewController, success) in
                AssetDataSourceBackupManager.shared.deleteBackup()
                
                welf?.navigationController?.popToRootViewController(animated: true)
                if success {
                    NotificationCenter.default.post(name: SelectedAssetsManager.notificationNamePhotobookComplete, object: nil)
                }
            }) {
                welf?.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
        }
        return photobookViewController
    }
}

extension AssetPickerCollectionViewController: PhotobookDelegate {
    
    func assetPickerViewController() -> PhotobookAssetPickerController {
        let modalAlbumsCollectionViewController = mainStoryboard.instantiateViewController(withIdentifier: "ModalAlbumsCollectionViewController") as! ModalAlbumsCollectionViewController
        modalAlbumsCollectionViewController.album = album
        modalAlbumsCollectionViewController.albumManager = albumManager

        return modalAlbumsCollectionViewController
    }
}

extension AssetPickerCollectionViewController {
    //MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return !album.assets.isEmpty ? album.assets.count : Constants.numberOfAssetPlaceholders
        case 1:
            return album.hasMoreAssetsToLoad ? 1 : 0
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetPickerCollectionViewCell", for: indexPath) as? AssetPickerCollectionViewCell else { return UICollectionViewCell() }
            
            guard indexPath.item < album.assets.count else { return cell }
                
            let asset = album.assets[indexPath.item]
            cell.assetId = asset.identifier
            
            cell.imageView.setImage(from: asset, size: imageCellSize, validCellCheck: {
                return cell.assetId == asset.identifier
            })
            
            return cell
        case 1:
            return collectionView.dequeueReusableCell(withReuseIdentifier: Constants.loadingCellReuseIdentifier, for: indexPath)
        default:
            return UICollectionViewCell()
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            // We only show covers for Stories
            guard let story = album as? Story,
                let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "coverCell", for: indexPath) as? AssetPickerCoverCollectionViewCell
                else { return UICollectionReusableView() }
            
            let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: indexPath.section)
            story.coverAsset(completionHandler: {(asset) in
                cell.setCover(cover: asset, size: size)
            })
            
            cell.title = story.title
            cell.dates = story.subtitle
            
            return cell
        default:
            return UICollectionReusableView(frame: CGRect())
        }
    }
    
}

extension AssetPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // We only show covers for Stories
        guard (album as? Story) != nil, section == 0 else { return .zero }
        
        return CGSize(width: view.bounds.size.width, height: view.bounds.size.width / AssetPickerCollectionViewController.coverAspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return imageCellSize
        case 1:
            return CGSize(width: collectionView.frame.size.width, height: 40)
        default:
            return .zero
        }
    }
}

extension AssetPickerCollectionViewController {
    //MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedAssetsManager = selectedAssetsManager,
            !album.assets.isEmpty
            else {
                return
        }
        let asset = album.assets[indexPath.item]
        
        guard selectedAssetsManager.toggleSelected(asset) else {
            let alertController = UIAlertController(title: NSLocalizedString("ImagePicker/TooManyPicturesAlertTitle", value: "Too many pictures", comment: "Alert title informing the user that they have reached the maximum number of images"), message: NSLocalizedString("ImagePicker/TooManyPicturesAlertMessage", value: "Your photo book cannot contain more than \(PhotobookSDK.shared.maximumAllowedPhotos) pictures", comment: "Alert message informing the user that they have reached the maximum number of images"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        updateSelectedStatus(indexPath: indexPath, asset: asset)
        
        updateSelectAllButton()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 0, indexPath.item < album.assets.count, let cell = cell as? AssetPickerCollectionViewCell {
            updateSelectedStatus(cell: cell, indexPath: indexPath, asset: album.assets[indexPath.item])
            return
        }
        
        guard cell.reuseIdentifier == Constants.loadingCellReuseIdentifier else { return }
        let previousAssetCount = album.assets.count
        album.loadNextBatchOfAssets() { [weak welf = self] (error) in
            guard let stelf = welf else { return }
            if let error = error {
                stelf.showErrorMessage(error: error, dismissAfter: 3.0) {}
                return
            }
            
            stelf.collectionView?.performBatchUpdates({
                // Insert new albums
                var indexPaths = [IndexPath]()
                for i in previousAssetCount ..< stelf.album.assets.count {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                stelf.collectionView?.insertItems(at: indexPaths)
                
                // Remove spinner cell if all assets have been loaded
                if !stelf.album.hasMoreAssetsToLoad {
                    stelf.collectionView?.deleteItems(at: [IndexPath(row: 0, section: 1)])
                }
            }, completion: nil)
        }
    }
}

extension AssetPickerCollectionViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? AssetPickerCollectionViewCell,
            let thumbnailImage = cell.imageView.image
            else { return nil }
        
        let fullScreenImageViewController = mainStoryboard.instantiateViewController(withIdentifier: "FullScreenImageViewController") as! FullScreenImageViewController
        previewingContext.sourceRect = cell.convert(cell.contentView.frame, to: collectionView)
        
        fullScreenImageViewController.asset = album.assets[indexPath.item]
        fullScreenImageViewController.selectedAssetsManager = selectedAssetsManager
        fullScreenImageViewController.delegate = self
        fullScreenImageViewController.providesPresentationContextTransitionStyle = true
        fullScreenImageViewController.definesPresentationContext = true
        fullScreenImageViewController.modalPresentationStyle = .overCurrentContext
        
        // Use the cell's image to calculate the image's aspect ratio
        fullScreenImageViewController.preferredContentSize = CGSize(width: view.frame.size.width, height: view.frame.size.width * (thumbnailImage.size.height / thumbnailImage.size.width) - 1) // -1 because otherwise a black line can be seen above the image
        
        return fullScreenImageViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let fullScreenImageViewController = viewControllerToCommit as? FullScreenImageViewController else { return }
        fullScreenImageViewController.prepareForPop()
        fullScreenImageViewController.modalPresentationCapturesStatusBarAppearance = true
        
        delegate?.viewControllerForPresentingOn()?.present(viewControllerToCommit, animated: true, completion: nil)
    }
    
}

extension AssetPickerCollectionViewController: FullScreenImageViewControllerDelegate {
    // MARK: FullScreenImageViewControllerDelegate
    
    func previewDidUpdate(asset: PhotobookAsset) {
        guard let index = album.assets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }),
            index != NSNotFound
            else { return }
        
        collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
    
    func sourceView(for asset: PhotobookAsset) -> UIView?{
        guard let index = album.assets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }),
            index != NSNotFound,
        let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? AssetPickerCollectionViewCell
            else { return nil }
        
        return cell.imageView
        
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension AssetPickerCollectionViewController: AssetPickerCollectionViewControllerDelegate {
    func viewControllerForPresentingOn() -> UIViewController? {
        return tabBarController
    }
    
}
