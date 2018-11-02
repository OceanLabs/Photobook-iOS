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

let hasShownTutorialKey = "PhotobookTutorialShown"

struct CommonLocalizedStrings {
    static let somethingWentWrongTitle = NSLocalizedString("GenericError/SomethingWentWrong", value: "Something Went Wrong", comment: "Generic error message title")
    static let somethingWentWrongText = NSLocalizedString("GenericError/AnErrorOcurred", value: "An error occurred while processing your request.", comment: "Generic error message body")
    static let alertOK = NSLocalizedString("Generic/OKButtonTitle", value: "OK", comment: "Acknowledgement to an alert dialog")
    static let retry = NSLocalizedString("General/RetryButtonTitle", value: "Retry", comment: "Button title to retry operation")
    static let cancel = NSLocalizedString("General/CancelButtonTitle", value: "Cancel", comment: "Cancel an action")
    static let yes = NSLocalizedString("General/YesButtonTitle", value: "Yes", comment: "Agree to an action")
    static let no = NSLocalizedString("General/NoButtonTitle", value: "No", comment: "Don't agree to an action")
    static let done = NSLocalizedString("General/Done", value: "Done", comment: "Agree with changes and finalise")
    static let next = NSLocalizedString("General/Next", value: "Next", comment: "Proceed to the next step")

    static let checkConnectionAndRetry = NSLocalizedString("Generic/CheckConnectionAndRetry", value: "Please check your internet connectivity and try again.", comment: "Message instructing the user to check their Internet connection.")
    static let accessibilityListItemSelected = NSLocalizedString("Accessibility/ListItemSelected", value: "Selected", comment: "Accessibility message to let the user know that an item in a list is selected.") + ". "
    static let accessibilityDoubleTapToSelectListItem = NSLocalizedString("Accessibility/DoubleTapToSelectListItem", value: "Double tap to select.", comment: "Accessibility hint letting the user know that they can double tap to select a list item")
    static let accessibilityDoubleTapToEdit = NSLocalizedString("Accessibility/DoubleTapToEdit", value: "Double tap to edit.", comment: "Accessibility hint letting the user know that they can double tap to edit an item")

    static func serviceAccessError(serviceName: String) -> String {
        return NSLocalizedString("Generic/AccessError", value: "There was an error when trying to access \(serviceName)", comment: "Generic error when trying to access a social service eg Instagram/Facebook")
    }
}
