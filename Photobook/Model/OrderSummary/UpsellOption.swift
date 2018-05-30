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
    var targetTemplateId: String?
    
    var dict: [String: Any] {
        get {
            var dictionary = ["type": type, "displayName": displayName]
            if let targetTemplateId = targetTemplateId { dictionary["targetTemplateId"] = targetTemplateId }
            return dictionary
        }
    }
    
    init(type: String, displayName: String, targetTemplateId: String? = nil) {
        self.type = type
        self.displayName = displayName
        self.targetTemplateId = targetTemplateId
    }
    
    static func parse(_ dict: [String: Any]) -> UpsellOption? {
        guard let type = dict["type"] as? String, let displayName = dict["displayName"] as? String else {
            //invalid
            print("UpsellOption: couldn't initialise object")
            return nil
        }
        
        let targetTemplateId = dict["targetTemplateId"] as? String
        
        return UpsellOption(type: type, displayName: displayName, targetTemplateId: targetTemplateId)
    }
}

func ==(lhs: UpsellOption, rhs: UpsellOption) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension UpsellOption: Hashable {
    var hashValue: Int {
        get {
            var value = type.hashValue ^ displayName.hashValue
            if let targetTemplateId = targetTemplateId { value = value ^ targetTemplateId.hashValue}
            return value
        }
    }
}
