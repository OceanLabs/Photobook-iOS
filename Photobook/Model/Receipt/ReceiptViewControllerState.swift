//
//  ReceiptViewControllerModel.swift
//  Photobook
//
//  Created by Julian Gruber on 22/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

enum ReceiptViewControllerState: Int {
    case uploading
    case error
    case completed
    case cancelled
    case paymentFailed
    case paymentRetry
    
    var title:String {
        get {
            switch self {
            case .uploading:
                return Constants.titleUploading
            case .error:
                return Constants.titleError
            case .completed:
                return Constants.titleCompleted
            case .cancelled:
                return Constants.titleCancelled
            case .paymentFailed, .paymentRetry:
                return Constants.titlePaymentFailed
            }
        }
    }
    
    var emoji:String? {
        get {
            switch self {
            case .error: return "😰"
            case .completed: return "👍"
            case .cancelled: return "😵"
            case .paymentFailed, .paymentRetry: return "😔"
            default: return nil
            }
        }
    }
    
    var infoTitle:String? {
        get {
            switch self {
            case .error: return Constants.infoTitleError.uppercased()
            case .completed: return Constants.infoTitleCompleted.uppercased()
            case .cancelled: return Constants.infoTitleCancelled.uppercased()
            case .paymentFailed, .paymentRetry: return Constants.infoTitlePaymentFailed.uppercased()
            default: return nil
            }
        }
    }
    
    var infoText:String? {
        get {
            switch self {
            case .error: return Constants.infoDescriptionError
            case .completed: return Constants.infoDescriptionCompleted
            case .cancelled: return Constants.infoDescriptionCancelled
            case .paymentFailed, .paymentRetry: return Constants.infoDescriptionPaymentFailed.uppercased()
            default: return nil
            }
        }
    }
    
    var actionsHidden:Bool {
        get {
            if self == .error || self == .paymentRetry || self == .paymentFailed {
                return false
            }
            return true
        }
    }
    
    var secondaryActionHidden:Bool {
        get {
            if self == .paymentRetry {
                return false
            }
            return true
        }
    }
    
    var primaryActionText:String? {
        get {
            switch self {
            case .paymentFailed: return Constants.infoButtonTitleUpdate.uppercased()
            case .paymentRetry, .error: return Constants.infoButtonTitleRetry.uppercased()
            default: return nil
            }
        }
    }
    
    var secondaryActionText:String? {
        get {
            if self == .paymentRetry {
                return Constants.infoButtonTitleUpdate.uppercased()
            }
            return nil
        }
    }
    
    var allowDismissing:Bool {
        get {
            switch self {
            case .uploading: return false
            case .error, .completed, .cancelled, .paymentFailed, .paymentRetry: return true
            }
        }
    }
    
    var dismissTitle:String? {
        get {
            switch self {
            case .completed: return Constants.dismissTitleSuccess
            case .error, .cancelled, .paymentFailed, .paymentRetry: return Constants.dismissTitleFailed
            default: return nil
            }
        }
    }
    
    private struct Constants {
        static let titleCompleted = NSLocalizedString("ReceiptViewControllerState/TitleCompleted", value: "Order Complete", comment: "Receipt sceen title when successfully completed uploading images and order is confirmed")
        static let titleError = NSLocalizedString("ReceiptViewControllerState/TitleError", value: "Upload Failed", comment: "Receipt sceen title when uploading images fails")
        static let titleCancelled = NSLocalizedString("ReceiptViewControllerState/TitleCancelled", value: "Order Cancelled", comment: "Receipt sceen title if order had to be cancelled because of unresolvable technical problems")
        static let titlePaymentFailed = NSLocalizedString("ReceiptViewControllerState/TitlePaymentFailed", value: "Payment Failed", comment: "Receipt sceen title if payment fails and payment method has to be updated")
        static let titleUploading = NSLocalizedString("ReceiptViewControllerState/TitleUploading", value: "Processing Order", comment: "Receipt sceen title when uploading images")
        
        static let infoTitleCompleted = NSLocalizedString("ReceiptViewControllerState/InfoTitleCompleted", value: "Ready to Print", comment: "Status title if order has been completed and product is ready to print")
        static let infoDescriptionCompleted = NSLocalizedString("ReceiptViewControllerState/InfoDescriptionCompleted", value: "We have received your photos and we will begin processing your photo book shortly", comment: "Info text when order has been completed")
        static let infoTitleError = NSLocalizedString("ReceiptViewControllerState/InfoTitleError", value: "Something Went Wrong!", comment: "Status title if order couldn't be completed")
        static let infoDescriptionError = NSLocalizedString("ReceiptViewControllerState/InfoDescriptionError", value: "Something happened and we can't receive your photos at this point. You can retry or cancel and be refunded", comment: "Info text when order couldn't be completed")
        static let infoTitleCancelled = NSLocalizedString("ReceiptViewControllerState/InfoTitleCancelled", value: "Order Cancelled", comment: "Status title if was cancelled")
        static let infoDescriptionCancelled = NSLocalizedString("ReceiptViewControllerState/InfoDescriptionCancelled", value: "Something happened and we can't receive your photos at this point but we haven't charged you anything", comment: "Info text when order couldn't be completed")
        static let infoTitlePaymentFailed = NSLocalizedString("ReceiptViewControllerState/InfoTitlePaymentFailed", value: "Your Payment Method Failed", comment: "Payment has failed")
        static let infoDescriptionPaymentFailed = NSLocalizedString("ReceiptViewControllerState/InfoDescriptionPaymentFailed", value: "The charge for your book was declined.\nYou can retry with another method", comment: "Info text when payment method has failed")
        
        static let infoButtonTitleRetry = NSLocalizedString("ReceiptViewControllerState/InfoButtonRetry", value: "Retry", comment: "Info button text when order couldn't be completed")
        static let infoButtonTitleOK = NSLocalizedString("ReceiptViewControllerState/InfoButtonCancelled", value: "OK", comment: "Info button when order was cancelled")
        static let infoButtonTitleUpdate = NSLocalizedString("ReceiptViewControllerState/InfoButtonPaymentFailed", value: "Update", comment: "Info button when payment has failed and payment method can be updated")
        
        static let dismissTitleSuccess = NSLocalizedString("ReceiptViewControllerState/DismissButtonSuccess", value: "Continue", comment: "Button displayed after order was placed successfully")
        static let dismissTitleFailed = NSLocalizedString("ReceiptViewControllerState/DismissButtonFail", value: "Cancel", comment: "Button displayed when something has gone wrong and order couldn't be placed. This gives the user the option to cancel the upload and purchase")
    }
}


