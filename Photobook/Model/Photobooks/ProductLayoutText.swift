//
//  ProductLayoutText.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutText {
    var containerSize: CGSize! {
        didSet {
            // TODO: Apply text limitations
        }
    }
    var text: String?    
}
