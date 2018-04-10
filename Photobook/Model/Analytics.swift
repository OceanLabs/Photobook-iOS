//
//  Analytics.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import KeychainSwift
import Analytics

class Analytics {
    
    enum ScreenName: String {
        case stories = "Stories"
        case albums = "Albums"
        case facebookAlbums = "Facebook Albums"
        case albumsAddingMorePhotos = "Albums adding more photos"
        case facebookAlbumsAddingMorePhotos = "Facebook albums adding more photos"
        case picker = "Picker"
        case storiesPicker = "Stories Picker"
        case facebookPicker = "Facebook Picker"
        case instagramPicker = "Instagram Picker"
        case pickerAddingMorePhotos = "Picker adding more photos"
        case storiesPickerAddingMorePhotos = "Stories picker adding more photos"
        case instagramPickerAddingMorePhotos = "Instagram picker adding more photos"
        case facebookPickerAddingMorePhotos = "Facebook picker adding more photos"
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
        case appOpened = "App opened"
        case photoSourceSelected = "Photo source selected"
        case pickerSelectAllTapped = "Picker select all tapped"
        case pickerDeselectAllTapped = "Picker deselect all tapped"
        case collectorSelectionCleared = "Collector selection cleared"
        case collectorUseTheseTapped = "Collector use these tapped"
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
        case editingCancelled = "Editing cancelled"
        case editingConfirmed = "Editing confirmed"
        case uploadCancelled = "Upload cancelled"
        case uploadRetried = "Upload retried"
        case uploadSuccessful = "Upload successful"
    }
    
    enum ErrorName: String {
        case photobookInfo = "Photobook information error"
        case diskError = "Image saving error"
        case imageUpload = "Image upload error"
        case pdfCreation = "PDF creation error"
        case orderSubmission = "Order submission error"
        case payment = "Payment error"
    }
    
    struct PropertyNames {
        static let photoSourceName = "Photo source name"
        static let numberOfPhotosSelected = "Number of photos selected"
        static let upsellOptionName = "Upsell option name"
        static let secondsSinceAppOpen = "Seconds since app open"
        static let secondsInEditing = "Seconds in editing"
        static let secondsInBackground = "Seconds in background"
        static let environment = "Environment"
    }
    
    private struct Constants {
        static let userIdKeychainKey = "userIdKeychainKey"
    }
    
    static let shared = Analytics()
    
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
            
            SEGAnalytics.shared().identify(userId)
        }
        
        return userId
    }
    
    init() {
        let analyticsConfiguration = SEGAnalyticsConfiguration(writeKey: "kFnvwFEImWDbOLGZxaQVwP86bpf4nKO8")
        analyticsConfiguration.trackApplicationLifecycleEvents = true
        SEGAnalytics.setup(with: analyticsConfiguration)
        
        // Track application state change
        // By tracking .didFinishLaunching and .willEnterForeground, instead of .didBecomeActive we avoid notifications when the user doesn't exit the app, for example when they invoke control center
        NotificationCenter.default.addObserver(forName: .UIApplicationDidFinishLaunching, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.trackAction(.appOpened)
            welf?.appLaunchDate = Date()
        })
        
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.trackAction(.appOpened)
            
            guard let appBackgroundedDate = welf?.appBackgroundedDate else { return }
            welf?.secondsSpentInBackground += Date().timeIntervalSince(appBackgroundedDate)
        })
        
        NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
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
        
        SEGAnalytics.shared().screen(screenName.rawValue, properties: properties)
    }
    
    func trackAction(_ actionName: ActionName, _ properties: [String: Any]? = nil){
        #if DEBUG
            print("Analytics: Action \"\(actionName.rawValue)\" triggered. Properties: \(properties ?? [:])")
        #endif
        
        let properties = addEnvironment(to: properties)
        
        SEGAnalytics.shared().track(actionName.rawValue, properties: properties)
    }
    
    func trackError(_ errorName: ErrorName) {
        #if DEBUG
            print("Analytics: Error \"\(errorName.rawValue)\" happened")
        #endif
        
        let properties = addEnvironment(to: [:])
        
        SEGAnalytics.shared().track(errorName.rawValue, properties: properties)
    }
    
    func secondsSinceAppOpen() -> Int {
        return Int(Date().timeIntervalSince(appLaunchDate))
    }
}
