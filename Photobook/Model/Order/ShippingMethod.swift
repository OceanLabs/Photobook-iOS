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

import Foundation

@objc public class ShippingMethod: NSObject, Codable, NSCoding {
    
    static var supportsSecureCoding = true
    
    @objc public let id: Int
    let name: String
    let price: Price
    let maxDeliveryTime: Int
    let minDeliveryTime: Int

    var deliveryTime: String {
        return String.localizedStringWithFormat(NSLocalizedString("ShippingMethod/DeliveryTime", value:"%d to %d working days", comment: "Delivery estimates for a specific delivery method"), minDeliveryTime, maxDeliveryTime)
    }
    
    init(id: Int, name: String, price: Price, maxDeliveryTime: Int, minDeliveryTime: Int) {
        self.id = id
        self.name = name
        self.price = price
        self.maxDeliveryTime = maxDeliveryTime
        self.minDeliveryTime = minDeliveryTime
    }
    
    static func parse(dictionary: [String: Any]) -> ShippingMethod? {
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["mobile_shipping_name"] as? String,
            let costsDictionaries = dictionary["costs"] as? [[String: Any]],
            
            let price = Price.parse(costsDictionaries),
            
            let maxDeliveryTime = dictionary["max_delivery_time"] as? Int,
            let minDeliveryTime = dictionary["min_delivery_time"] as? Int
            else { return nil }
        
        return ShippingMethod(id: id, name: name, price: price, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let data = try? PropertyListEncoder().encode(self) {
            aCoder.encode(data, forKey: "shippingMethodData")
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        guard let data = aDecoder.decodeObject(forKey: "shippingMethodData") as? Data,
            let unarchived = try? PropertyListDecoder().decode(ShippingMethod.self, from: data)
            else {
                return nil
        }
        
        id = unarchived.id
        name = unarchived.name
        price = unarchived.price
        maxDeliveryTime = unarchived.maxDeliveryTime
        minDeliveryTime = unarchived.minDeliveryTime
    }
    
    static func ==(lhs: ShippingMethod, rhs: ShippingMethod) -> Bool{
        return lhs.id == rhs.id
    }
}
