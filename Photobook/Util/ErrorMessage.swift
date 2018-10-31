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
        if let apiError = error as? APIClientError {
            self.init(apiError, title)
        } else {
            self.init(title: title, text: (error as NSError).localizedDescription)
        }
    }
    
    init(_ error: APIClientError, _ title: String? = nil) {
        self.title = title
        switch error {
        case .connection:
            self.title = NSLocalizedString("ConnectionErrorTitle", value: "You Appear to be Offline", comment: "Connection error title")
            text = NSLocalizedString("ConnectionErrorMessage", value: "Please check your internet connectivity and try again.", comment: "Connection error Message")
            type = .info
        case .server(let code, let message) where code == 500 && message == "":
            self.title = NSLocalizedString("ServerMaintenanceErrorTitle", value: "Server Maintenance", comment: "Server maintenance error title")
            text = NSLocalizedString("ServerMaintenanceErrorMessage", value: "We'll be back and running as soon as possible!", comment: "Server maintenance error message")
            type = .error
        case .server(_, let message) where !message.isEmpty:
            text = message
            type = .error
        default:
            self.title = CommonLocalizedStrings.somethingWentWrongTitle
            text = CommonLocalizedStrings.somethingWentWrongText
            type = .error
        }
    }
}

