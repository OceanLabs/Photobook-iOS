//
//  ReceiptViewControllerModel.swift
//  Photobook
//
//  Created by Julian Gruber on 22/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

class ReceiptViewControllerModel {
    
    struct Constants {
        static let infoTitleCompleted = NSLocalizedString("ReceiptTableViewController/InfoTitleCompleted", value: "Ready to Print", comment: "Status title if order has been completed and product is ready to print")
        static let infoDescriptionCompleted = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCompleted", value: "We have received your photos and we will begin processing your photobook shortly", comment: "Info text when order has been completed")
        static let infoTitleError = NSLocalizedString("ReceiptTableViewController/InfoTitleError", value: "Something Went Wrong!", comment: "Status title if order couldn't be completed")
        static let infoDescriptionError = NSLocalizedString("ReceiptTableViewController/InfoDescriptionError", value: "Something happened and we can't receive your photos at this point. You can retry or cancel and be refunded", comment: "Info text when order couldn't be completed")
        static let infoTitleCancelled = NSLocalizedString("ReceiptTableViewController/InfoTitleCancelled", value: "Order Cancelled", comment: "Status title if was cancelled")
        static let infoDescriptionCancelled = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCancelled", value: "Something happened and we can't receive your photos at this point but we haven't charged you anything", comment: "Info text when order couldn't be completed")
        static let infoTitlePaymentFailed = NSLocalizedString("ReceiptTableViewController/InfoTitlePaymentFailed", value: "Your Payment Method Failed", comment: "Payment has failed")
        static let infoDescriptionPaymentFailed = NSLocalizedString("ReceiptTableViewController/InfoDescriptionPaymentFailed", value: "The charge for your book was declined.\nYou can retry with another method", comment: "Info text when payment method has failed")
        
        static let loadingPaymentText = NSLocalizedString("Controllers/ReceiptTableViewController/PaymentLoadingText",
                                                          value: "Preparing Payment",
                                                          comment: "Info text displayed while preparing for payment service")
        static let loadingFinishingOrderText = NSLocalizedString("Controllers/ReceiptTableViewController/loadingFinishingOrderText",
                                                                 value: "Finishing order",
                                                                 comment: "Info text displayed while finishing order")
        
        static let infoButtonTitleRetry = NSLocalizedString("ReceiptTableViewController/InfoButtonRetry", value: "Retry", comment: "Info button text when order couldn't be completed")
        static let infoButtonTitleOK = NSLocalizedString("ReceiptTableViewController/InfoButtonCancelled", value: "OK", comment: "Info button when order was cancelled")
        static let infoButtonTitleUpdate = NSLocalizedString("ReceiptTableViewController/InfoButtonPaymentFailed", value: "Update", comment: "Info button when payment has failed and payment method can be updated")
        
        static let dismissTitleSuccess = NSLocalizedString("ReceiptTableViewController/DismissButtonSuccess", value: "Continue", comment: "Button displayed after order was placed successfully")
        static let dismissTitleFailed = NSLocalizedString("ReceiptTableViewController/DismissButtonFail", value: "Cancel", comment: "Button displayed when something has gone wrong and order couldn't be placed. This gives the user the option to cancel the upload and purchase")
    }
    
    enum State: Int {
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
                    return NSLocalizedString("ReceiptTableViewController/TitleUploading", value: "Processing Order", comment: "Receipt sceen title when uploading images")
                case .error:
                    return NSLocalizedString("ReceiptTableViewController/TitleError", value: "Upload Failed", comment: "Receipt sceen title when uploading images fails")
                case .completed:
                    return NSLocalizedString("ReceiptTableViewController/TitleCompleted", value: "Order Complete", comment: "Receipt sceen title when successfully completed uploading images and order is confirmed")
                case .cancelled:
                    return NSLocalizedString("ReceiptTableViewController/TitleCancelled", value: "Order Cancelled", comment: "Receipt sceen title if order had to be cancelled because of unresolvable technical problems")
                case .paymentFailed, .paymentRetry:
                    return NSLocalizedString("ReceiptTableViewController/TitlePaymentFailed", value: "Payment Failed", comment: "Receipt sceen title if payment fails and payment method has to be updated")
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
    }
}


