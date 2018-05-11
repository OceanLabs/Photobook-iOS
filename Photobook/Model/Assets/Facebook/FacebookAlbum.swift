//
//  FacebookAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import FBSDKLoginKit

protocol FacebookApiManager {
    var accessToken: String? { get }
    func request(withGraphPath path: String, parameters: [String: Any]?, completion: @escaping (Any?, Error?) -> Void)
}

class DefaultFacebookApiManager: FacebookApiManager {
    var accessToken: String? {
        return FBSDKAccessToken.current().tokenString
    }
    func request(withGraphPath path: String, parameters: [String : Any]?, completion: @escaping (Any?, Error?) -> Void) {
        let graphRequest = FBSDKGraphRequest(graphPath: path, parameters: parameters)
        _ = graphRequest?.start { _, result, error in
            completion(result, error)
        }
    }
}

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
    private var after: String?
    
    var graphPath: String {
        return "\(identifier)/photos?fields=picture,source,id,images&limit=\(Constants.pageSize)"
    }
    
    lazy var facebookManager: FacebookApiManager = DefaultFacebookApiManager()
    
    private func fetchAssets(graphPath: String, completionHandler: ((Error?) -> Void)?) {
        facebookManager.request(withGraphPath: graphPath, parameters: nil) { [weak welf = self] (result, error) in
            if let error = error {
                completionHandler?(ErrorMessage(text: error.localizedDescription))
                return
            }
            
            guard let result = (result as? [String: Any]), let data = result["data"] as? [[String: Any]]
                else {
                    completionHandler?(ErrorMessage(text: CommonLocalizedStrings.serviceAccessError(serviceName: Constants.serviceName)))
                    return
            }
            
            var newAssets = [Asset]()
            for photo in data {
                guard let identifier = photo["id"] as? String,
                    let images = photo["images"] as? [[String: Any]]
                    else { continue }
                
                var urlAssetImages = [URLAssetImage]()
                for image in images {
                    guard let source = image["source"] as? String,
                        let url = URL(string: source),
                        let width = image["width"] as? Int,
                        let height = image["height"] as? Int
                        else { continue }
                    urlAssetImages.append(URLAssetImage(url: url, size: CGSize(width: width, height: height)))
                }
                
                if let newAsset = URLAsset(identifier: identifier, images: urlAssetImages, albumIdentifier: self.identifier) {
                    newAssets.append(newAsset)
                    welf?.assets.append(newAsset)
                }
            }
            
            // Get the next page cursor
            if let paging = result["paging"] as? [String: Any],
                paging["next"] != nil,
                let cursors = paging["cursors"] as? [String: Any],
                let after = cursors["after"] as? String {
                self.after = after
            } else {
                self.after = nil
            }
            
            completionHandler?(nil)
        }
    }
}

extension FacebookAlbum: Album {
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        fetchAssets(graphPath: graphPath, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {
        guard let after = after else { return }
        let graphPath = self.graphPath + "&after=\(after)"
        fetchAssets(graphPath: graphPath, completionHandler: completionHandler)
    }
    
    var hasMoreAssetsToLoad: Bool {
        return after != nil
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        completionHandler(URLAsset(identifier: coverPhotoUrl.absoluteString, images: [URLAssetImage(url: coverPhotoUrl, size: .zero)], albumIdentifier: identifier), nil)
    }
}

extension FacebookAlbum: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .facebookPicker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .facebookPickerAddingMorePhotos }
}
