//
//  InstagramAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 15/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import KeychainSwift
import OAuthSwift

protocol InstagramApiManager {
    func startAuthorizedRequest(_ url: String,
                                method: OAuthSwiftHTTPRequest.Method,
                                onTokenRenewal: OAuthSwift.TokenRenewedHandler?,
                                success: @escaping OAuthSwiftHTTPRequest.SuccessHandler,
                                failure: @escaping OAuthSwiftHTTPRequest.FailureHandler)
}

protocol KeychainHandler {
    var tokenKey: String? { get set }
}

class DefaultInstagramApiManager: InstagramApiManager {
    func startAuthorizedRequest(_ url: String,
                                method: OAuthSwiftHTTPRequest.Method,
                                onTokenRenewal: OAuthSwift.TokenRenewedHandler?,
                                success: @escaping OAuthSwiftHTTPRequest.SuccessHandler,
                                failure: @escaping OAuthSwiftHTTPRequest.FailureHandler) {
        InstagramClient.shared.startAuthorizedRequest(url, method: method, parameters: [:], onTokenRenewal: onTokenRenewal, success: success, failure: failure)
    }
}

class DefaultKeychainHandler: KeychainHandler {
    var tokenKey: String? {
        get { return KeychainSwift().get(InstagramClient.Constants.keychainInstagramTokenKey) }
        set {
            if let newValue = newValue {
                KeychainSwift().set(newValue, forKey: InstagramClient.Constants.keychainInstagramTokenKey)
            }
        }
    }
}

class InstagramAlbum {
    
    private struct Constants {
        static let instagramMediaBaseUrl = "https://api.instagram.com/v1/users/self/media/recent"
        static let pageSize = 100
    }
    
    var assets = [Asset]()
    let identifier = UUID.init().uuidString
    private var nextUrl: String?
    var hasMoreAssetsToLoad: Bool {
        return nextUrl != nil
    }
    
    lazy var instagramApiManager: InstagramApiManager = DefaultInstagramApiManager()
    lazy var keychainHandler: KeychainHandler = DefaultKeychainHandler()
    
    func fetchAssets(url: String, completionHandler:((_ error: Error?)->())?) {
        guard let token = keychainHandler.tokenKey else {
            completionHandler?(ErrorMessage(text: CommonLocalizedStrings.serviceAccessError(serviceName: InstagramClient.Constants.serviceName)))
            return
        }
        
        var urlToLoad = url
        
        if !urlToLoad.contains("access_token") {
            urlToLoad = "\(urlToLoad)?access_token=\(token)"
        }
        urlToLoad = "\(urlToLoad)&count=\(Constants.pageSize)"
        
        instagramApiManager.startAuthorizedRequest(urlToLoad, method: .GET, onTokenRenewal: { [weak welf = self] (credential) in
            welf?.keychainHandler.tokenKey = credential.oauthToken
        }, success: { response in
            guard let json = (try? JSONSerialization.jsonObject(with: response.data, options: [])) as? [String : Any],
                let pagination = json["pagination"] as? [String : Any],
                let data = json["data"] as? [[String : Any]]
                else {
                    completionHandler?(ErrorMessage(text: CommonLocalizedStrings.serviceAccessError(serviceName: InstagramClient.Constants.serviceName)))
                    return
            }
            
            self.nextUrl = pagination["next_url"] as? String
            var newAssets = [Asset]()
            
            for d in data {
                var media = [[String : Any]]()
                if let array = d["carousel_media"] as? [[String : Any]] {
                    for imagesDict in array {
                        guard let images = imagesDict["images"] as? [String : Any] else { continue }
                        media.append(images)
                    }
                } else if let images = d["images"] as? [String : Any] {
                    media.append(images)
                }
                
                guard let identifier = d["id"] as? String else { continue }
                
                for i in 0 ..< media.count {
                    let images = media[i]
                    var urlAssetImages = [URLAssetImage]()
                    for key in ["standard_resolution", "low_resolution", "thumbnail"] {
                        guard let image = images[key] as? [String : Any],
                            let width = image["width"] as? Int,
                            let height = image["height"] as? Int,
                            let standardResolutionImageUrlString = image["url"] as? String,
                            let standardResolutionImageUrl = URL(string: standardResolutionImageUrlString)
                            else { continue }
                        
                        urlAssetImages.append(URLAssetImage(url: standardResolutionImageUrl, size: CGSize(width: width, height: height)))
                    }
                    
                    if let urlAsset = URLAsset(identifier: "\(identifier)-\(i)", images: urlAssetImages, albumIdentifier: self.identifier) {
                        newAssets.append(urlAsset)
                    }
                }
            }
            
            self.assets.append(contentsOf: newAssets)
            
            completionHandler?(nil)
        }) { failure in
            // Not worth showing an error if one of the later pagination requests fail
            guard self.assets.isEmpty else { return }
            
            if ((failure.underlyingError as NSError?)?.userInfo["Response-Body"] as? String)?.contains("OAuthAccessTokenException") == true {
                completionHandler?(AccountError.notLoggedIn)
                return
            }
            
            let message = failure.underlyingError?.localizedDescription ?? CommonLocalizedStrings.serviceAccessError(serviceName: InstagramClient.Constants.serviceName)
            completionHandler?(ErrorMessage(text: message))
        }
    }
}

extension InstagramAlbum: Album {
        
    var numberOfAssets: Int {
        return assets.count
    }
    
    var localizedName: String? {
        return "Instagram"
    }
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        fetchAssets(url: Constants.instagramMediaBaseUrl, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {
        guard let url = nextUrl else { return }
        fetchAssets(url: url, completionHandler: completionHandler)
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        return completionHandler(assets.first, nil)
    }
}

extension InstagramAlbum: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .instagramPicker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .instagramPickerAddingMorePhotos }
}
