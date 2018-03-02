//
//  FacebookAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FacebookAlbum {
    
    private struct Constants {
        static let pageSize = 100
        static let serviceName = "Facebook"
    }
    
    init(identifier: String, localizedName: String, numberOfAssets: Int, coverPhotoUrl: URL) {
        self.identifier = identifier
        self.localizedName = localizedName
        self.numberOfAssets = numberOfAssets
        self.coverPhotoUrl = coverPhotoUrl
    }
    
    var numberOfAssets: Int
    
    var localizedName: String?
    
    var identifier: String
    
    var assets = [Asset]()
        
    var coverPhotoUrl: URL
    
    var after: String?
    
    var graphPath: String {
        return "\(identifier)/photos?fields=picture,source,id,images&limit=\(Constants.pageSize)"
    }
    
    private func fetchAssets(graphPath: String, completionHandler: ((Error?) -> Void)?) {
        let graphRequest = FBSDKGraphRequest(graphPath: graphPath, parameters: [:])
        _ = graphRequest?.start(completionHandler: { [weak welf = self] _, result, error in
            if let error = error {
                // Not worth showing an error if one of the later pagination requests fail
                guard self.assets.isEmpty else { return }
                completionHandler?(ErrorUtils.genericRetryErrorMessage(message: error.localizedDescription, action: {
                    welf?.fetchAssets(graphPath: graphPath, completionHandler: completionHandler)
                }))
                return
            }
            
            guard let result = (result as? [String: Any]), let data = result["data"] as? [[String: Any]]
                else {
                    // Not worth showing an error if one of the later pagination requests fail
                    guard self.assets.isEmpty else { return }
                    completionHandler?(ErrorMessage(message: CommonLocalizedStrings.serviceAccessError(serviceName: Constants.serviceName)))
                    return
            }
            
            var newAssets = [Asset]()
            for photo in data {
                guard let thumbnailUrlString = photo["picture"] as? String,
                    let thumbnailUrl = URL(string: thumbnailUrlString),
                    let fullResolutionUrlString = photo["source"] as? String,
                    let fullResolutionUrl = URL(string: fullResolutionUrlString),
                    let identifier = photo["id"] as? String,
                    let images = photo["images"] as? [[String: Any]]
                    else { continue }
                
                let newAsset = URLAsset(thumbnailUrl: thumbnailUrl, fullResolutionUrl: fullResolutionUrl, albumIdentifier: self.identifier, identifier: identifier)
                
                for image in images {
                    guard let source = image["source"] as? String,
                        let width = image["width"] as? Int,
                        let height = image["height"] as? Int
                        else { continue }
                    if source == fullResolutionUrlString {
                        newAsset.size = CGSize(width: width, height: height)
                    } else if source == thumbnailUrlString {
                        newAsset.thumbnailSize = CGSize(width: width, height: height)
                    }
                }
                
                newAssets.append(newAsset)
                welf?.assets.append(newAsset)
            }
            
            // Get the next page cursor
            if let paging = result["paging"] as? [String: Any],
                paging["next"] != nil,
                let cursors = paging["cursors"] as? [String: Any],
                let after = cursors["after"] as? String {
                self.after = after
            }
            
            // Call the completion handler only on the first request, subsequent requests will update the album
            if let completionHandler = completionHandler {
                completionHandler(nil)
            } else {
                NotificationCenter.default.post(name: AssetsNotificationName.albumsWereUpdated, object: [AlbumChange(album: self, assetsRemoved: [], indexesRemoved: [], assetsAdded: newAssets)])
            }
        
        })
    }

}

extension FacebookAlbum: Album {
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        fetchAssets(graphPath: graphPath, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets() {
        guard let after = after else { return }
        self.after = nil
        let graphPath = self.graphPath + "&after=\(after)"
        fetchAssets(graphPath: graphPath, completionHandler: nil)
    }
    
    var hasMoreAssetsToLoad: Bool {
        return after != nil
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        completionHandler(URLAsset(fullResolutionUrl: coverPhotoUrl, albumIdentifier: identifier, identifier: coverPhotoUrl.absoluteString), nil)
    }
}
