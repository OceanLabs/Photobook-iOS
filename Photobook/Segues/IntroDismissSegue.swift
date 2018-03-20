//
//  IntroDismissSegue.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 14/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class IntroDismissSegue: UIStoryboardSegue {
    
    override func perform() {
        
        let push = { self.source.navigationController?.setViewControllers([self.destination], animated: false) }
        
        guard let sourceSnapShot = source.view.snapshotView(afterScreenUpdates: true) else { push(); return }
        source.navigationController?.view.addSubview(sourceSnapShot)
        push()
        
        UIView.animate(withDuration: 0.15, animations: {
            sourceSnapShot.alpha = 0
        }, completion: { _ in sourceSnapShot.removeFromSuperview() })
        
    }

}
