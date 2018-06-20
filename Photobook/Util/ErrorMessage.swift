//
//  ErrorMessage.swift
//  Shopify
//
//  Created by Jaime Landazuri on 10/10/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

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
    
    init?(_ error: Error?, _ title: String? = nil) {
        guard let error = error else { return nil }
        
        if let apiError = error as? APIClientError {
            self.init(apiError, title)
        } else {
            self.init(title: title, text: (error as NSError).localizedDescription)
        }
    }
    
    init?(_ error: APIClientError?, _ title: String? = nil) {
        guard let error = error else { return nil }
        
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
        case .server(_, let message) where message != "":
            text = message
            type = .error
        default:
            self.title = CommonLocalizedStrings.somethingWentWrong
            text = NSLocalizedString("GenericError/AnErrorOcurred", value: "An error occurred while processing your request.", comment: "Generic error message body")
            type = .error
        }
    }
}

