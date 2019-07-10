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

// Information about a page layout
struct Layout: Equatable, Codable {
    let id: Int!
    let category: String!
    var imageLayoutBox: LayoutBox?
    var textLayoutBox: LayoutBox?
    var isDoubleLayout: Bool = false
    
    func isEmptyLayout() -> Bool { return imageLayoutBox == nil && textLayoutBox == nil }
    func isLandscape() -> Bool { return imageLayoutBox != nil && imageLayoutBox!.isLandscape() }
    
    static func parse(_ layoutDictionary: [String: AnyObject]) -> Layout? {
        guard
            let id = layoutDictionary["id"] as? Int,
            let category = layoutDictionary["category"] as? String
            else { return nil }
        
        var layout = Layout(id: id, category: category, imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        
        if let layoutBoxesDictionary = layoutDictionary["layoutBoxes"] as? [[String: AnyObject]] {
            for layoutBoxDictionary in layoutBoxesDictionary {
                guard let type = layoutBoxDictionary["type"] as? String else { continue }
                
                if type == "image" { layout.imageLayoutBox = LayoutBox.parse(layoutBoxDictionary) }
                else if type == "text" { layout.textLayoutBox = LayoutBox.parse(layoutBoxDictionary) }
            }
        }
        
        // TEMP: Avoid parsing double layouts as the PDF generation does not support them
        if let doubleLayout = layoutDictionary["isDoublePage"] as? Bool, doubleLayout {
            return nil
        }
        
        return layout
    }
    
    static func ==(lhs: Layout, rhs: Layout) -> Bool {
        return lhs.id == rhs.id && lhs.category == rhs.category
    }
}
