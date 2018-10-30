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

class OrderSummary {
    
    struct Detail {
        var name: String
        var price: String
        
        init(name: String, price: String) {
            self.name = name
            self.price = price
        }
        
        init?(_ dict: [String: Any]) {
            guard var name = dict["name"] as? String,
                let priceDict = dict["price"] as? [String:Any],
                let amountDouble = priceDict["amount"] as? Double,
                let currencyCode = priceDict["currencyCode"] as? String else {
                //invalid
                print("OrderSummary.Detail: couldn't initialise")
                return nil
            }
            
            // Ugly Hack for PicCollage in Kostas & Jaime's absence. To be removed on their return
            // when we can get a more correct solution in place.
            if name == "Square 210x210" {
                name = "8x8\" Book"
            }
            
            self.init(name: name, price: Decimal(amountDouble).formattedCost(currencyCode: currencyCode))
        }
    }
    
    private(set) var details = [Detail]()
    private(set) var total: String
    private(set) var pigBaseUrl: String
    
    private init(details: [Detail], total: String, pigBaseUrl: String) {
        self.details = details
        self.total = total
        self.pigBaseUrl = pigBaseUrl
    }
    
    static func parse(_ dict: [String:Any]) -> OrderSummary? {
        guard let dictionaries = dict["lineItems"] as? [[String:Any]],
            let totalDict = dict["total"] as? [String: Any],
            let totalDouble = totalDict["amount"] as? Double,
            let currencyCode = totalDict["currencyCode"] as? String,
            let imageUrl = dict["previewImageUrl"] as? String else {
            print("OrderSummary: couldn't initialise")
            return nil
        }
        
        var details = [Detail]()
        for d in dictionaries {
            if let detail = Detail(d) {
                details.append(detail)
            } else {
                return nil //all line items have to be valid
            }
        }
        
        return OrderSummary(details: details, total: Decimal(totalDouble).formattedCost(currencyCode: currencyCode), pigBaseUrl: imageUrl)
    }    
}
