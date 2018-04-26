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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var progressSpinnerImageView: UIImageView!
    
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
        progressLabel.text = String(format: progressFormatString, max(uploadedCount, 1), totalUploads)
        
        progressView.setProgress(Float(uploadedCount+1)/Float(totalUploads), animated: false)
    }
    
}
