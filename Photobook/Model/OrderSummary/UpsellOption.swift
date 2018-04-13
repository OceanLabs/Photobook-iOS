//
//  UpsellOption.swift
//  Photobook
//
//  Created by Julian Gruber on 26/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class UpsellOption: Equatable {
    var type: String
    var displayName: String
    var payload: AnyObject?
    
    init(type: String, displayName: String, payload: AnyObject?) {
        self.type = type
        self.displayName = displayName
        self.payload = payload
    }
    
    convenience init?(_ dict: [String: Any]) {
        guard let type = dict["type"] as? String, let displayName = dict["displayName"] as? String else {
            //invalid
            print("UpsellOption: couldn't initialise object")
            return nil
        }
        
        self.init(type: type, displayName: displayName, payload: dict["payload"] as AnyObject)
    }
}

func ==(lhs: UpsellOption, rhs: UpsellOption) -> Bool {
    return lhs.type == rhs.type
}

extension UpsellOption: Hashable {
    var hashValue: Int {
        get {
            return type.hashValue
        }
    }
}
