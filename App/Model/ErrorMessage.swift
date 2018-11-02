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

/// Type of message
///
/// - info: General info for the user
/// - error: Severe error in response to a user action or server request.
/// - warning: Inform the user of critical information in the current context
enum MessageType {
    case info
    case error
    case warning
    
    func backgroundColor() -> UIColor {
        switch self {
        case .error:
            return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        case .warning:
            return UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0)
        case .info:
            return UIColor(red: 0.64, green: 0.64, blue: 0.64, alpha: 1.0)
        }
    }
}

/// Simplifies error handling at VC level keeping messages independent from the API client.
struct ErrorMessage: Error {
    private(set) var title: String?
    private(set) var text: String!
    private(set) var type: MessageType!
    
    init(title: String? = nil, text: String) {
        self.title = title
        self.text = text
        self.type = .error
    }
    
    init(_ error: Error, _ title: String? = nil) {
        self.init(title: title, text: (error as NSError).localizedDescription)
    }    
}

