//
//  PhotoBookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var ctaButtonContainer: UIView!
    var selectedAssetsManager: SelectedAssetsManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        setupTitleView()
        
        selectedAssetsManager?.sortAssets(minimumNumberOfAssets: 21) //TODO: Replace with product minimum
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var bottomInset = ctaButtonContainer.frame.size.height
        
        if #available(iOS 11.0, *) {
            bottomInset -= view.safeAreaInsets.bottom
        }
        
        collectionView.contentInset = UIEdgeInsets(top: collectionView.contentInset.top, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }
    
    func setupTitleView() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center;
        titleLabel.text = "210x210 mm" //TODO: Replace with product name
        
        let chevronView = UIImageView(image: UIImage(named:"chevron-down"))
        chevronView.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        stackView.spacing = 5
        
        stackView.isUserInteractionEnabled = true;
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnTitle)))
        
        navigationItem.titleView = stackView;
    }
    
    @objc func didTapOnTitle() {
        print("Tapped on title")
    }

    @IBAction func didTapRearrange(_ sender: UIBarButtonItem) {
        //TODO: Enter rearrange mode
    }
    
    @IBAction func didTapCheckout(_ sender: UIButton) {
        print("Tapped Checkout")
    }
    
}

extension PhotoBookViewController: UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        case 2:
            return ((selectedAssetsManager?.assets.count ?? 0 ) - 3) / 2
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section{
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as? PhotoBookCoverCollectionViewCell else { return UICollectionViewCell() }
            
            //Don't bother calculating the exact size, request a slightly larger size
            //TODO: handle full width pages
            let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
            selectedAssetsManager?.assets[0].image(size: imageSize, completionHandler: { (image, _) in
                cell.coverView.coverPage.image = image
            })
            
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotoBookCollectionViewCell else { return UICollectionViewCell() }
            
            let rightIndex = 1
            cell.bookView.leftIndex = nil
            cell.bookView.rightIndex = rightIndex
            
            //Don't bother calculating the exact size, request a slightly larger size
            //TODO: handle full width pages
            let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
            selectedAssetsManager?.assets[rightIndex].image(size: imageSize, completionHandler: { (image, _) in
                guard cell.bookView.rightIndex == rightIndex, let image = image else { return }
                
                cell.bookView.rightPage.image = image
            })
            
            return cell
        case 2:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotoBookCollectionViewCell else { return UICollectionViewCell() }
            
            let leftIndex = indexPath.item * 2 + 2
            cell.bookView.leftIndex = leftIndex
            
            let rightIndex = indexPath.item * 2 + 3
            cell.bookView.rightIndex = rightIndex
            
            //Don't bother calculating the exact size, request a slightly larger size
            //TODO: handle full width pages
            let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
            selectedAssetsManager?.assets[leftIndex].image(size: imageSize, completionHandler: { (image, _) in
                guard cell.bookView.leftIndex == leftIndex, let image = image else { return }
                
                cell.bookView.leftPage.image = image
            })
            
            selectedAssetsManager?.assets[rightIndex].image(size: imageSize, completionHandler: { (image, _) in
                guard cell.bookView.rightIndex == rightIndex, let image = image else { return }
                
                cell.bookView.rightPage.image = image
            })
            
            return cell
        case 3:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotoBookCollectionViewCell else { return UICollectionViewCell() }
            
            let leftIndex = (selectedAssetsManager?.assets.count ?? 0) - 1
            cell.bookView.leftIndex = leftIndex
            cell.bookView.rightIndex = nil
            
            //Don't bother calculating the exact size, request a slightly larger size
            //TODO: handle full width pages
            let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
            selectedAssetsManager?.assets[leftIndex].image(size: imageSize, completionHandler: { (image, _) in
                guard cell.bookView.leftIndex == leftIndex, let image = image else { return }
                
                cell.bookView.leftPage.image = image
            })
            
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
}

extension PhotoBookViewController: UICollectionViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotoBookNavigationBar else { return }
        
        navBar.effectView.alpha = scrollView.contentOffset.y <= -(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height ?? 0)) ? 0 : 1
    }
    
}
