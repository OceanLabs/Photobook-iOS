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

class ReceiptProgressTableViewCell: UITableViewCell {

    static let reuseIdentifier = NSStringFromClass(ReceiptProgressTableViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private weak var titleLabel: UILabel! { didSet { titleLabel.scaleFont() } }
    @IBOutlet private weak var descriptionLabel: UILabel! { didSet { descriptionLabel.scaleFont() } }
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressLabel: UILabel! { didSet { progressLabel.scaleFont() } }
    @IBOutlet private weak var infoLabel: UILabel! { didSet { infoLabel.scaleFont() } }    
    @IBOutlet private weak var progressSpinnerImageView: UIImageView!
    
    private func startProgressAnimation() {
        guard progressSpinnerImageView.layer.animation(forKey: "rotation") == nil else { return }
        
        let fromValue = progressSpinnerImageView.layer.presentation()?.value(forKeyPath: "transform.rotation") as? CGFloat ?? 0.0
        
        // Start progress spinner
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = fromValue
        rotateAnimation.toValue = fromValue + CGFloat(.pi * 2.0)
        rotateAnimation.duration = 1.5
        rotateAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        progressSpinnerImageView.layer.add(rotateAnimation, forKey: "rotation")
    }
    
    func updateProgress(_ progress: Double, pendingUploads: Int, totalUploads: Int) {
        startProgressAnimation()
        let uploadedCount = totalUploads - pendingUploads
        
        let progressFormatString = NSLocalizedString("ReceiptProgressTableViewCell/ProgressFormatString", value: "%d of %d photos", comment: "Amount of photos uploaded compared to the total count. Example '7 of 24 photos'")
        let startingCount = max(uploadedCount, 0)
        progressLabel.text = String(format: progressFormatString, startingCount, totalUploads)        
        progressView.setProgress(Float(progress) / Float(totalUploads), animated: false)
    }
}
