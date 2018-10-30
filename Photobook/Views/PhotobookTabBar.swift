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

class PhotobookTabBar: UITabBar {
    
    var effectView: UIVisualEffectView?
    var tabChangeObserver: NSKeyValueObservation?
    
    var isBackgroundHidden:Bool = false {
        didSet {
            effectView?.alpha = isBackgroundHidden ? 0 : 1
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        effectView?.frame = bounds
    }
    
    func setup() {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        self.effectView = effectView
        
        effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        insertSubview(effectView, at: 0)
        backgroundImage = UIImage(color: .clear)
        shadowImage = UIImage()
        
        tabChangeObserver = observe(\.selectedItem, options: [.new,.old], changeHandler: { tabBar, change in
            guard let oldValue = change.oldValue,
                let newValueTitle = tabBar.selectedItem?.title,
                newValueTitle != oldValue?.title
                else { return }
            Analytics.shared.trackAction(.photoSourceSelected, [Analytics.PropertyNames.photoSourceName: newValueTitle])
        })
    }
    
}
