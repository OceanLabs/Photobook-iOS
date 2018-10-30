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

class FullScreenImageUnwindSegue: UIStoryboardSegue {

    override func perform() {
        guard let source = source as? FullScreenImageViewController,
            let sourceView = source.delegate?.sourceView(for: source.asset),
            let sourceViewSuperview = sourceView.superview
            else {
                self.source.dismiss(animated: true, completion: nil)
                return
        }
        
        sourceView.isHidden = true
        
        let imageView = source.imageView!
        
        //Add a copy image view to animate back to the thumbnail
        let animationImageView = UIImageView(image: imageView.image)
        animationImageView.frame = imageView.frame
        animationImageView.contentMode = .scaleAspectFill
        animationImageView.clipsToBounds = true
        source.view.addSubview(animationImageView)
        imageView.isHidden = true
        
        let endFrame = (sourceViewSuperview.convert(sourceView.frame, to: source.view))
        
        UIView.animate(withDuration: 0.25, animations: {
            animationImageView.frame = endFrame
            source.view.backgroundColor = UIColor.clear
        }, completion:{(finished: Bool) in
            sourceView.isHidden = false
            source.dismiss(animated: false, completion: nil)
        })
        
    }
    
}
