//
//  ReceiptProgressTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 05/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptProgressTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(ReceiptProgressTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                titleLabel.font = UIFontMetrics.default.scaledFont(for: titleLabel.font)
                titleLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                descriptionLabel.font = UIFontMetrics.default.scaledFont(for: descriptionLabel.font)
                descriptionLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                progressLabel.font = UIFontMetrics.default.scaledFont(for: progressLabel.font)
                progressLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var infoLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                infoLabel.font = UIFontMetrics.default.scaledFont(for: infoLabel.font)
                infoLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    @IBOutlet private weak var progressSpinnerImageView: UIImageView!
    
    func startProgressAnimation() {
        let fromValue = progressSpinnerImageView.layer.presentation()?.value(forKeyPath: "transform.rotation") as? CGFloat ?? 0.0
        
        //start progress spinner
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = fromValue
        rotateAnimation.toValue = fromValue + CGFloat(.pi * 2.0)
        rotateAnimation.duration = 1.5
        rotateAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        progressSpinnerImageView.layer.add(rotateAnimation, forKey: "rotation")
    }
    
    func updateProgress(pendingUploads:Int, totalUploads:Int) {
        let uploadedCount = totalUploads - pendingUploads
        
        let progressFormatString = NSLocalizedString("ReceiptProgressTableViewCell/ProgressFormatString", value: "%d of %d photos", comment: "Amount of photos uploaded compared to the total count. Example '7 of 24 photos'")
        let startingCount = max(uploadedCount, 1)
        progressLabel.text = String(format: progressFormatString, startingCount, totalUploads)        
        progressView.setProgress(Float(startingCount) / Float(totalUploads), animated: false)
    }
    
}
