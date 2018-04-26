//
//  UpsellOption.swift
//  Photobook
//
//  Created by Julian Gruber on 26/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class UpsellOption: Codable, Equatable {
    var type: String
    var displayName: String
    private var payloadData: Data?
    var payload: AnyObject? {
        guard let data = payloadData else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    }
    
    init(type: String, displayName: String, payload: Data?) {
        self.type = type
        self.displayName = displayName
        self.payloadData = payload
    }
    
    convenience init?(_ dict: [String: Any]) {
        guard let type = dict["type"] as? String, let displayName = dict["displayName"] as? String else {
            //invalid
            print("UpsellOption: couldn't initialise object")
            return nil
        }
        
        let payloadData = try? JSONSerialization.data(withJSONObject: dict["payload"] as Any, options: [])
        
        self.init(type: type, displayName: displayName, payload: payloadData)
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
