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
import KeychainSwift
import Analytics

@objc public protocol AnalyticsDelegate {
    @objc func photobookAnalyticsEventDidFire(type: AnalyticsEventType, name: String, properties: [String: Any])
}

@objc public enum AnalyticsEventType: Int {
    case screenViewed
    case action
    case error
}

@objc public class Analytics: NSObject {
    
    enum ScreenName: String {
        case photobook = "Photobook"
        case pageEditingPhotoSelection = "Page editing / Photo selection"
        case colorSelection = "Color selection"
        case layoutSelection = "Layout selection"
        case photoPlacement = "Photo placement"
        case textEditing = "Text editing"
        case spineTextEditing = "Spine text editing"
        case summary = "Summary"
        case basket = "Basket"
        case paymentMethods = "Payment methods"
        case receipt = "Receipt"
    }
    
    enum ActionName: String {
        case wentBackFromPhotobookPreview = "Went back from photobook preview"
        case addedPages = "Added pages"
        case pastedPages = "Pages pages"
        case deletedPages = "Deleted pages"
        case rearrangedPages = "Rearranged pages"
        case addedTextToPage = "Added text to page"
        case usingDoublePageLayout = "Using a double page layout"
        case selectedUpsellOption = "Selected upsell option"
        case deselectedUpsellOption = "Deselected upsell option"
        case coverLayoutChanged = "Cover layout changed"
        case orderSubmitted = "Order submitted"
        case orderCompleted = "Order completed"
        case editingCancelled = "Editing cancelled"
        case editingConfirmed = "Editing confirmed"
        case paymentRetried = "Payment retried"
        case uploadCancelled = "Upload cancelled"
        case uploadRetried = "Upload retried"
        case uploadSuccessful = "Upload successful"
    }
    
    enum ErrorName: String {
        case productInfo = "Product information error"
        case diskError = "Image saving error"
        case imageUpload = "Image upload error"
        case pdfCreation = "PDF creation error"
        case orderSubmission = "Order submission error"
        case payment = "Payment error"
        case parsing = "Parsing error"
        case upsellError = "Upsell error"
    }
    
    struct PropertyNames {
        static let upsellOptionName = "Upsell option name"
        static let secondsInEditing = "Seconds in editing"
        static let secondsSinceAppOpen = "Seconds since app open"
        static let secondsInBackground = "Seconds in background"
        static let environment = "Environment"
    }
    
    private struct Constants {
        static let userIdKeychainKey = "userIdKeychainKey"
    }
    
    @objc public static let shared = Analytics()
    @objc public weak var delegate: AnalyticsDelegate?
    @objc public var optInToRemoteAnalytics = false
    
    private var appLaunchDate = Date()
    private var appBackgroundedDate: Date?
    private(set) var secondsSpentInBackground: TimeInterval = 0
    
    var userDistinctId: String {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        
        var userId: String! = keychain.get(Constants.userIdKeychainKey)
        if userId == nil {
            userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID.init().uuidString
            keychain.set(userId, forKey: Constants.userIdKeychainKey)
            
            SEGAnalytics.shared()?.identify(userId)
        }
        
        return userId
    }
    
    override init() {
        super.init()
        let analyticsConfiguration = SEGAnalyticsConfiguration(writeKey: "kFnvwFEImWDbOLGZxaQVwP86bpf4nKO8")
        analyticsConfiguration.trackApplicationLifecycleEvents = true
        SEGAnalytics.setup(with: analyticsConfiguration)
        
        // Track application state change
        // By tracking .didFinishLaunching and .willEnterForeground, instead of .didBecomeActive we avoid notifications when the user doesn't exit the app, for example when they invoke control center
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.appLaunchDate = Date()
        })
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            guard let appBackgroundedDate = welf?.appBackgroundedDate else { return }
            welf?.secondsSpentInBackground += Date().timeIntervalSince(appBackgroundedDate)
        })
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.appBackgroundedDate = Date()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addEnvironment(to properties:[String: Any]?) -> [String: Any] {
        let environment = APIClient.environment == .test ? "Test" : "Live"
        
        var properties = properties ?? [:]
        properties[PropertyNames.environment] = environment
        
        return properties
    }
    
    func trackScreenViewed(_ screenName: ScreenName, _ properties: [String: Any]? = nil) {
        
        #if DEBUG
            print("Analytics: Screen \"\(screenName.rawValue)\" viewed. Properties: \(properties ?? [:])")
        #endif
        
        let properties = addEnvironment(to: properties)
        
        if optInToRemoteAnalytics {
            SEGAnalytics.shared()?.screen(screenName.rawValue, properties: properties)
        }
        delegate?.photobookAnalyticsEventDidFire(type: .screenViewed, name: screenName.rawValue, properties: properties)
    }
    
    func trackAction(_ actionName: ActionName, _ properties: [String: Any]? = nil){
        #if DEBUG
            print("Analytics: Action \"\(actionName.rawValue)\" triggered. Properties: \(properties ?? [:])")
        #endif
        
        let properties = addEnvironment(to: properties)
        
        if optInToRemoteAnalytics {
            SEGAnalytics.shared()?.track(actionName.rawValue, properties: properties)
        }
        delegate?.photobookAnalyticsEventDidFire(type: .action, name: actionName.rawValue, properties: properties)
    }
    
    func trackError(_ errorName: ErrorName, _ details: String) {
        trackError(errorName, ["details": details])
    }
    
    func trackError(_ errorName: ErrorName, _ properties: [String: Any]? = nil) {
        #if DEBUG
            print("Analytics: Error \"\(errorName.rawValue)\" happened. Properties: \(properties ?? [:])")
        #endif
        
        let properties = addEnvironment(to: properties)
        
        // TODO: Remove once it's ok from a legal point to track errors (TOS update etc)
        if optInToRemoteAnalytics {
            SEGAnalytics.shared()?.track(errorName.rawValue, properties: properties)
        }
        delegate?.photobookAnalyticsEventDidFire(type: .error, name: errorName.rawValue, properties: properties)
    }
    
    func secondsSinceAppOpen() -> Int {
        return Int(Date().timeIntervalSince(appLaunchDate))
    }
}
