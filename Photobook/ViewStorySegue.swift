//
//  ViewStorySegue.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ViewStorySegue: UIStoryboardSegue {

    override func perform() {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
}
