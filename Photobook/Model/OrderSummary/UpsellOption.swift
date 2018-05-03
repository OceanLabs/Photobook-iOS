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
    var sourceTemplateId: String
    var targetTemplateId: String?
    
    var dict: [String: Any] {
        get {
            var dictionary = ["type": type, "displayName": displayName, "sourceTemplateId": sourceTemplateId]
            if let targetTemplateId = targetTemplateId { dictionary["targetTemplateId"] = targetTemplateId }
            return dictionary
        }
    }
    
    init(type: String, displayName: String, sourceTemplateId: String, targetTemplateId: String? = nil) {
        self.type = type
        self.displayName = displayName
        self.sourceTemplateId = sourceTemplateId
        self.targetTemplateId = targetTemplateId
    }
    
    convenience init?(_ dict: [String: Any]) {
        guard let type = dict["type"] as? String, let displayName = dict["displayName"] as? String, let sourceTemplateId = dict["sourceTemplateId"] as? String else {
            //invalid
            print("UpsellOption: couldn't initialise object")
            return nil
        }
        
        self.init(type: type, displayName: displayName, sourceTemplateId: sourceTemplateId, targetTemplateId: dict["targetTemplateId"] as? String)
    }
    
    //TODO: remove mock data and get from summary endpoint once implemented
    static func upsells(forProduct product: PhotobookProduct) -> [UpsellOption] {
        var upsells = [UpsellOption]()
        if let jsonDict = JSON.parse(file: "upsells") as? [String: Any],
            let upsellDicts = jsonDict["upsells"] as? [[String: Any]] {
            for upsellDict in upsellDicts {
                if let upsell = UpsellOption(upsellDict) {
                    upsells.append(upsell)
                }
            }
        }
        upsells = upsells.filter { (upsell) -> Bool in
            print("\(upsell.sourceTemplateId) == \(product.template.productTemplateId!)")
            return upsell.sourceTemplateId == product.template.productTemplateId!
        }
        return upsells
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
