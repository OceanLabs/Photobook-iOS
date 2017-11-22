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
    var selectedAssetsManager: SelectedAssetsManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        setupTitleView()
        
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (selectedAssetsManager?.count() ?? 0 ) / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookCell", for: indexPath) as? PhotoBookCollectionViewCell else { return UICollectionViewCell() }
        
        let leftIndex = indexPath.item * 2
        cell.leftIndex = leftIndex
        
        let rightIndex = indexPath.item * 2 + 1
        cell.rightIndex = rightIndex
        
        selectedAssetsManager?.assets()[leftIndex].image(size: CGSize(width: 100, height: 100), completionHandler: { (image, _) in
            guard cell.leftIndex == leftIndex else { return }
            
            cell.bookView.leftPageImageView.image = image
        })
        
        selectedAssetsManager?.assets()[rightIndex].image(size: CGSize(width: 100, height: 100), completionHandler: { (image, _) in
            guard cell.rightIndex == rightIndex else { return }
            
            cell.bookView.rightPageImageView.image = image
        })
        
        return cell
    }
}

extension PhotoBookViewController: UICollectionViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotoBookNavigationBar else { return }
        
        navBar.effectView.alpha = scrollView.contentOffset.y <= -(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height ?? 0)) ? 0 : 1
    }
    
}
