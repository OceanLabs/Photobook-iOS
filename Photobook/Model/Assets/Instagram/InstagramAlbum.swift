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
    }
    
    var assets: [Asset] = []
    var identifier: String = UUID.init().uuidString
    
    private lazy var instagramClient: OAuth2Swift = {
        let client = OAuth2Swift.instagramClient()
        return client
    }()
    
    init(authenticationHandler: OAuthSwiftURLHandlerType) {
        instagramClient.authorizeURLHandler = authenticationHandler
    }
    
    func fetchAssets(url: String? = nil, completionHandler:((_ assets: [Asset], _ next: Any?, _ error: Error?)->())?) {
        guard let tokenData = KeychainSwift().getData(keychainInstagramTokenKey),
            let token = String(data: tokenData, encoding: .utf8)
            else { return }
        
        var url = url ?? Constants.instagramMediaBaseUrl
        
        if !url.contains("access_token") {
            url = "\(url)?access_token=\(token)"
        }
        url = "\(url)&count=100"
        
        instagramClient.startAuthorizedRequest(url, method: .GET, parameters: [:], onTokenRenewal: { credential in
            KeychainSwift().set(credential.oauthToken, forKey: keychainInstagramTokenKey)
        }, success: { response in
            guard let json = (try? JSONSerialization.jsonObject(with: response.data, options: [])) as? [String : Any],
            let pagination = json["pagination"] as? [String : Any],
            let data = json["data"] as? [[String : Any]]
            else {
                // TODO: show error
                return
            }
            
            let nextUrl = pagination["next_url"] as? String
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
                    completionHandler?(newAssets, nil, nil)
                } else {
                    NotificationCenter.default.post(name: AssetsNotificationName.albumsWereReloaded, object: [AlbumChange(album: self, assetsRemoved: [], indexesRemoved: [], assetsAdded: newAssets)])
                }
            }
            
            if nextUrl != nil {
                self.fetchAssets(url: nextUrl, completionHandler: nil)
            }
            
        }, failure: { failure in
            print(failure)
            // TODO: show error
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
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        fetchAssets(completionHandler: { _,_, error in
            completionHandler?(error)
        })
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        
    }
}
