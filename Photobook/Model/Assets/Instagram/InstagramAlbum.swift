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

class InstagramAlbum {
    
    private struct Constants {
        static let instagramMediaBaseUrl = "https://api.instagram.com/v1/users/self/media/recent"
        static let serviceName = "Instagram"
        static let genericErrorMessage = NSLocalizedString("Social/AccessError", value: "There was an error when trying to access \(serviceName)", comment: "Generic error when trying to access a social service eg Instagram/Facebook")
    }
    
    var assets: [Asset] = []
    var identifier: String = UUID.init().uuidString
    private var nextUrl: String?
    var hasMoreAssetsToLoad: Bool {
        return nextUrl != nil
    }
    
    private lazy var instagramClient: OAuth2Swift = {
        let client = OAuth2Swift.instagramClient()
        return client
    }()
    
    init(authenticationHandler: OAuthSwiftURLHandlerType) {
        instagramClient.authorizeURLHandler = authenticationHandler
    }
    
    func fetchAssets(url: String, completionHandler:((_ error: ErrorMessage?)->())?) {
        guard let tokenData = KeychainSwift().getData(keychainInstagramTokenKey),
            let token = String(data: tokenData, encoding: .utf8)
            else { return }
        
        var urlToLoad = url
        
        if !urlToLoad.contains("access_token") {
            urlToLoad = "\(urlToLoad)?access_token=\(token)"
        }
        urlToLoad = "\(urlToLoad)&count=100"
        
        instagramClient.startAuthorizedRequest(urlToLoad, method: .GET, parameters: [:], onTokenRenewal: { credential in
            KeychainSwift().set(credential.oauthToken, forKey: keychainInstagramTokenKey)
        }, success: { response in
            guard let json = (try? JSONSerialization.jsonObject(with: response.data, options: [])) as? [String : Any],
            let pagination = json["pagination"] as? [String : Any],
            let data = json["data"] as? [[String : Any]]
            else {
                // Not worth showing an error if one of the later pagination requests fail
                guard self.assets.isEmpty else { return }
                
                completionHandler?(ErrorMessage(message: Constants.genericErrorMessage, retryButtonAction: { [weak welf = self] in
                    welf?.fetchAssets(url: url, completionHandler: completionHandler)
                }))
                
                return
            }
            
            self.nextUrl = pagination["next_url"] as? String
            var newAssets = [Asset]()
            
            for d in data {
                guard let images = d["images"] as? [String : Any],
                    let thumbnailImage = images["thumbnail"] as? [String : Any],
                    let thumbnailResolutionImageUrlString = thumbnailImage["url"] as? String,
                    let thumbnailResolutionImageUrl = URL(string: thumbnailResolutionImageUrlString),
                    
                    let standardResolutionImage = images["standard_resolution"] as? [String : Any],
                    let standardResolutionImageUrlString = standardResolutionImage["url"] as? String,
                    let standardResolutionImageUrl = URL(string: standardResolutionImageUrlString),
                    
                    let width = standardResolutionImage["width"] as? Int,
                    let height = standardResolutionImage["height"] as? Int,
                    
                    let identifier = d["id"] as? String
                    else { continue }
                
                newAssets.append(InstagramAsset(thumbnailUrl: thumbnailResolutionImageUrl, standardResolutionUrl: standardResolutionImageUrl, albumIdentifier: self.identifier, size: CGSize(width: width, height: height), identifier: identifier))
            }
            
            self.assets.append(contentsOf: newAssets)
            
            DispatchQueue.main.async {
                // Call the completion handler only on the first request, subsequent requests will update the album
                if completionHandler != nil {
                    completionHandler?(nil)
                } else {
                    NotificationCenter.default.post(name: AssetsNotificationName.albumsWereUpdated, object: [AlbumChange(album: self, assetsRemoved: [], indexesRemoved: [], assetsAdded: newAssets)])
                }
            }
        }, failure: { failure in
            // Not worth showing an error if one of the later pagination requests fail
            guard self.assets.isEmpty else { return }
            
            let message = failure.underlyingError?.localizedDescription ?? Constants.genericErrorMessage
            completionHandler?(ErrorMessage(message: message, retryButtonAction: { [weak welf = self] in
                welf?.fetchAssets(url: url, completionHandler: completionHandler)
            }))
        })
        
    }

}

extension InstagramAlbum: Album {
    
    var numberOfAssets: Int {
        return assets.count
    }
    var requiresExclusivePicking: Bool {
        return true
    }
    
    var localizedName: String? {
        return "Instagram"
    }
    
    func loadAssets(completionHandler: ((ErrorMessage?) -> Void)?) {
        fetchAssets(url: Constants.instagramMediaBaseUrl, completionHandler: {error in
            completionHandler?(error)
        })
    }
    
    func loadNextBatchOfAssets() {
        guard let url = nextUrl else { return }
        nextUrl = nil
        fetchAssets(url: url, completionHandler: nil)
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        return completionHandler(assets.first, nil)
    }
}
