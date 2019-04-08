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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(displayName)
        if let targetTemplateId = targetTemplateId {
            hasher.combine(targetTemplateId)
        }
    }
}
