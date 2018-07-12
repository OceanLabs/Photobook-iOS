//
//  AlbumsCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

/// View Controller to show albums. It doesn't care about the source of those albums as long as they conform to the Album protocol.
class AlbumsCollectionViewController: UICollectionViewController {
    
    private struct Constants {
        static let loadingCellReuseIdentifier = "LoadingCell"
        static let numberOfAlbumPlaceholders = 6
        static let timeToDismissMessages: TimeInterval = 3.0
    }
    
    var assetCollectorViewController: AssetCollectorViewController!
    
    /// The height between the bottom of the image and bottom of the cell where the labels sit
    private let albumCellLabelsHeight: CGFloat = 50
    private let marginBetweenAlbums: CGFloat = 20
    
    var albumManager: AlbumManager!
    private let selectedAssetsManager = SelectedAssetsManager()
    var assets: [Asset]!
    
    private var accountManager: AccountClient?
    var collectorMode: AssetCollectorMode = .selecting
    weak var addingDelegate: PhotobookAssetAddingDelegate?
    weak var assetPickerDelegate: AssetPickerCollectionViewControllerDelegate?
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    private lazy var albumCellSize: CGSize = {
        guard let collectionView = collectionView else { return .zero }
        var usableSpace = collectionView.frame.size.width - marginBetweenAlbums
        if let insets = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset{
            usableSpace -= insets.left + insets.right
        }
        let cellWidth = usableSpace / 2.0
        return CGSize(width: cellWidth, height: cellWidth + albumCellLabelsHeight)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pickerAnalytics = albumManager as? PickerAnalytics {
            let screenName = collectorMode == .selecting ? pickerAnalytics.selectingPhotosScreenName : pickerAnalytics.addingMorePhotosScreenName
            Analytics.shared.trackScreenViewed(screenName)
        }
        
        navigationItem.title = albumManager.title
        
        // Setup the Image Collector Controller
        assetCollectorViewController = AssetCollectorViewController.instance(fromStoryboardWithParent: self, selectedAssetsManager: selectedAssetsManager)
        assetCollectorViewController.mode = collectorMode
        assetCollectorViewController.delegate = self
        
        // Listen to asset manager
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
        
        // Listen for album changes
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereUpdated(_:)), name: AssetsNotificationName.albumsWereUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereAdded(_:)), name: AssetsNotificationName.albumsWereAdded, object: nil)
    }
    
    func loadAlbums() {
        guard albumManager.albums.isEmpty else { return }
        
        albumManager.loadAlbums() { [weak welf = self] (error) in
            guard error == nil else {
                welf?.showErrorMessage(error: error!) { welf?.loadAlbums() }
                return
            }
            
            welf?.collectionView?.reloadData()
        }
    }
    
    private func showErrorMessage(error: Error, dismissAfter: TimeInterval? = nil, completion: (() -> Void)?) {
        let message: ErrorMessage
        let offsetTop: CGFloat
        
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
        if collectorMode == .adding, let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar {
            offsetTop = navigationBar.barHeight
        } else { // Browse tab
            offsetTop = navigationController!.navigationBar.frame.maxY
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
        
        loadAlbums()
        
        // Refresh number of assets selected badges
        guard albumManager.albums.count > 0 else { return }
        for cell in collectionView?.visibleCells ?? [] {
            guard let cell = cell as? AlbumCollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell)
            else { continue }
            
            let album = albumManager.albums[indexPath.item]
            let selectedAssetsCount = selectedAssetsManager.count(for: album)
            cell.selectedCountLabel.text = "\(selectedAssetsCount)"
            cell.selectedCountLabel.isHidden = selectedAssetsCount == 0
        }
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        let searchResultsViewController = mainStoryboard.instantiateViewController(withIdentifier: "AlbumSearchResultsTableViewController") as! AlbumSearchResultsTableViewController
        searchResultsViewController.delegate = self
        searchResultsViewController.albums = self.albumManager.albums
        
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.searchBar.placeholder = NSLocalizedString("Albums/Search/BarPlaceholder", value: "Search Albums", comment: "Search bar placeholder text")
        searchController.searchBar.barTintColor = UIColor.white
        searchResultsViewController.searchBar = searchController.searchBar
        
        definesPresentationContext = true
        present(searchController, animated: true, completion: nil)
    }
    
    func showAlbum(album: Album){
        let assetPickerController = mainStoryboard.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
        assetPickerController.album = album
        assetPickerController.albumManager = albumManager
        assetPickerController.selectedAssetsManager = selectedAssetsManager
        assetPickerController.collectorMode = collectorMode
        assetPickerController.addingDelegate = addingDelegate
        assetPickerController.delegate = assetPickerDelegate ?? self
        
        self.navigationController?.pushViewController(assetPickerController, animated: true)
    }
    
    @objc private func selectedAssetManagerCountChanged(_ notification: NSNotification) {
        guard let assets = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyAssets] as? [Asset], let collectionView = collectionView else {
            return
        }
        var indexPathsToReload = [IndexPath]()
        for asset in assets {
            if let index = albumManager.albums.index(where: { (album) -> Bool in
                return album.identifier == asset.albumIdentifier
            }) {
                //check if indexpath is already added
                if indexPathsToReload.index(where: { (indexPath) -> Bool in
                    return indexPath.row == index
                }) == nil {
                    //not added yet, add
                    indexPathsToReload.append(IndexPath(row: index, section: 0))
                }
            }
        }
        
        collectionView.reloadItems(at: indexPathsToReload)
    }
    
    @objc func albumsWereUpdated(_ notification: Notification) {
        guard let albumsChanges = notification.object as? [AlbumChange] else { return }
        var indexPathsChanged = [IndexPath]()
        
        for albumChange in albumsChanges {
            guard let index = albumManager.albums.index(where: { $0.identifier == albumChange.album.identifier }) else { continue }
            indexPathsChanged.append(IndexPath(item: index, section: 0))
        }
        
        collectionView?.reloadItems(at: indexPathsChanged)
    }
    
    @objc func albumsWereAdded(_ notification: Notification) {
        guard let albumAdditions = notification.object as? [AlbumAddition] else { return }
        
        var indexPaths = [IndexPath]()
        for albumAddition in albumAdditions {
            indexPaths.append(IndexPath(item: albumAddition.index, section: 0))
        }
        
        collectionView?.performBatchUpdates({
            collectionView?.insertItems(at: indexPaths)
            collectionView?.reloadSections(IndexSet(integer: 1))
        }, completion: nil)
    }
    
}

extension AlbumsCollectionViewController: LogoutHandler {
    
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

extension AlbumsCollectionViewController: AssetCollectorViewControllerDelegate {
    // MARK: AssetCollectorViewControllerDelegate
    
    func actionsForAssetCollectorViewControllerHiddenStateChange(_ assetCollectorViewController: AssetCollectorViewController, willChangeTo hidden: Bool) -> () -> () {
        return { [weak welf = self] in
            let bottomInset: CGFloat
            if #available(iOS 11, *){
                bottomInset = hidden ? 0 : assetCollectorViewController.viewHeight
            } else {
                bottomInset = hidden ? assetCollectorViewController.viewHeight - assetCollectorViewController.view.transform.ty : assetCollectorViewController.viewHeight
            }
            welf?.collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        }
    }
    
    func assetCollectorViewControllerDidFinish(_ assetCollectorViewController: AssetCollectorViewController) {
        switch collectorMode {
        case .adding:
            let photobookAssets = PhotobookAsset.photobookAssets(with: selectedAssetsManager.selectedAssets)
            addingDelegate?.didFinishAdding(photobookAssets)
        default:
            let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
            photobookViewController.assets = selectedAssetsManager.selectedAssets
            photobookViewController.photobookDelegate = self
            photobookViewController.completionClosure = { (photobookProduct) in
                OrderManager.shared.basketOrder.products = [photobookProduct]
                
                let checkoutViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
                photobookViewController.navigationController?.pushViewController(checkoutViewController, animated: true)
            }

            navigationController?.pushViewController(photobookViewController, animated: true)
        }
    }
}

extension AlbumsCollectionViewController: PhotobookDelegate {
    
    var assetPickerViewController: PhotobookAssetPicker & UIViewController {
        let modalAlbumsCollectionViewController = mainStoryboard.instantiateViewController(withIdentifier: "ModalAlbumsCollectionViewController") as! ModalAlbumsCollectionViewController
        modalAlbumsCollectionViewController.albumManager = albumManager

        return modalAlbumsCollectionViewController
    }
}

extension AlbumsCollectionViewController{
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return albumManager.albums.isEmpty ? Constants.numberOfAlbumPlaceholders : albumManager.albums.count
        case 1:
            return albumManager.hasMoreAlbumsToLoad ? 1 : 0
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCollectionViewCell", for: indexPath) as? AlbumCollectionViewCell else { return UICollectionViewCell() }
            
            guard !albumManager.albums.isEmpty else {
                cell.albumNameLabel.text = ""
                cell.albumAssetsCountLabel.text = ""
                cell.selectedCountLabel.isHidden = true
                return cell
            }
            
            let album = albumManager.albums[indexPath.item]
            cell.albumId = album.identifier
            
            let cellWidth = (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 0
            album.coverAsset(completionHandler: { asset in
                cell.albumCoverImageView.setImage(from: asset, size: CGSize(width: cellWidth, height: cellWidth), validCellCheck: {
                    return cell.albumId == album.identifier
                })
            })
            
            cell.albumNameLabel.text = album.localizedName
            
            let totalNumberOfAssets = album.numberOfAssets
            cell.albumAssetsCountLabel.isHidden = totalNumberOfAssets == NSNotFound
            cell.albumAssetsCountLabel.text = "\(totalNumberOfAssets)"
            
            let selectedAssetsCount = selectedAssetsManager.count(for: album)
            cell.selectedCountLabel.text = "\(selectedAssetsCount)"
            cell.selectedCountLabel.isHidden = selectedAssetsCount == 0
            cell.selectedCountLabel.cornerRadius = cell.selectedCountLabel.frame.size.height / 2.0
            
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.loadingCellReuseIdentifier, for: indexPath)
            if let activityIndicator = cell.contentView.subviews.first as? UIActivityIndicatorView {
                activityIndicator.startAnimating()
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
}

extension AlbumsCollectionViewController: UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return albumCellSize
        case 1:
            return CGSize(width: collectionView.frame.size.width, height: 40)
        default:
            return .zero
        }
    }
}

extension AlbumsCollectionViewController {
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard albumManager.albums.count > 0 else { return }
        showAlbum(album: albumManager.albums[indexPath.item])
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard cell.reuseIdentifier == Constants.loadingCellReuseIdentifier else { return }
        let previousAlbumCount = albumManager.albums.count
        albumManager.loadNextBatchOfAlbums() { [weak welf = self] (error) in
            guard let stelf = welf else { return }
            if let error = error {
                stelf.showErrorMessage(error: error, dismissAfter: 3.0) {}
                return
            }
            
            stelf.collectionView?.performBatchUpdates({
                // Insert new albums
                var indexPaths = [IndexPath]()
                for i in previousAlbumCount ..< stelf.albumManager.albums.count {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }                
                stelf.collectionView?.insertItems(at: indexPaths)
                
                // Remove spinner cell if all albums have been loaded
                if !stelf.albumManager.hasMoreAlbumsToLoad {
                    stelf.collectionView?.deleteItems(at: [IndexPath(row: 0, section: 1)])
                }
            }, completion: nil)
        }
    }
}

extension AlbumsCollectionViewController: AlbumSearchResultsTableViewControllerDelegate {
    func searchDidSelect(_ album: Album) {
        showAlbum(album: album)
    }
    
}

extension AlbumsCollectionViewController: AssetPickerCollectionViewControllerDelegate {
    func viewControllerForPresentingOn() -> UIViewController? {
        return tabBarController
    }
    
}
