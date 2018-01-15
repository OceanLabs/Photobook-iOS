//
//  Order.swift
//  Photobook
//
//  Created by Julian Gruber on 08/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class Order {
    
    public var photobook: Photobook!
    public var selectedUpsellOptions:Set<String> = Set<String>() //ids of selected upsell options
    
    init(photobook:Photobook, selectedUpsellOptions:Set<String>) {
        self.photobook = photobook
        self.selectedUpsellOptions = selectedUpsellOptions
    }
}
