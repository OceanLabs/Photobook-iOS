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

class LineItem: Codable {
    
    let templateId: String
    let name: String
    let price: Price
    let identifier: String
    
    init(templateId: String, name: String, price: Price, identifier: String) {
        self.templateId = templateId
        self.name = name
        self.price = price
        self.identifier = identifier
    }
    
    static func parseDetails(dictionary: [String: Any], prioritizedCurrencyCodes: [String] = OrderManager.shared.prioritizedCurrencyCodes,  formattingLocale: Locale = Locale.current) -> LineItem? {
        guard
            let templateId = dictionary["template_id"] as? String,
            let name = dictionary["description"] as? String,
            let costDictionary = dictionary["product_costs"] as? [String: Any],
            let cost = Price.parse(costDictionary, prioritizedCurrencyCodes: prioritizedCurrencyCodes, formattingLocale: formattingLocale),
            let identifier = dictionary["job_id"] as? String
            else { return nil }
        
        return LineItem(templateId: templateId, name: name, price: cost, identifier: identifier)
    }
}
