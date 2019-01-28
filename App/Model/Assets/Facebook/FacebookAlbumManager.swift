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
import FBSDKLoginKit
import Photobook

class FacebookAlbumManager {
    
    private struct Constants {
        static let pageSize = 100
        static let graphPath = "me/albums?limit=\(pageSize)&fields=id,name,count,cover_photo"
    }
    
    var albums = [Album]()
    let title = NSLocalizedString("Albums/Facebook/Title", value: "Facebook Albums", comment: "Facebook Albums screen title")
    
    private var after: String?
    
    lazy var facebookManager: FacebookApiManager = DefaultFacebookApiManager()
    
    func fetchAlbums(graphPath: String, completionHandler: ((Error?) -> Void)?) {
        guard let token = facebookManager.accessToken else {
            completionHandler?(ErrorMessage(text: CommonLocalizedStrings.serviceAccessError(serviceName: FacebookClient.Constants.serviceName)))
            return
        }
        
        facebookManager.request(withGraphPath: graphPath, parameters: [:]) { [weak welf = self] result, error in
            if let error = error {
                let error = ErrorMessage(text: error.localizedDescription)
                completionHandler?(error)
                return
            }
            
            guard let result = (result as? [String: Any]), let data = result["data"] as? [[String: Any]]
                else {
                    completionHandler?(ErrorMessage(text: CommonLocalizedStrings.serviceAccessError(serviceName: FacebookClient.Constants.serviceName)))
                    return
            }
            
            var albumAdditions = [AlbumAddition]()
            for album in data {
                guard let albumId = album["id"] as? String,
                let photoCount = album["count"] as? Int,
                let name = album["name"] as? String,
                let coverPhoto = (album["cover_photo"] as? [String: Any])?["id"] as? String,
                let coverPhotoUrl = URL(string: "https://graph.facebook.com/\(coverPhoto)/picture?access_token=\(token)")
                    else { continue }
                
                if let stelf = welf {
                    albumAdditions.append(AlbumAddition(albumIdentifier: albumId, index: stelf.albums.count))
                    stelf.albums.append(FacebookAlbum(identifier: albumId, localizedName: name, numberOfAssets: photoCount, coverPhotoUrl: coverPhotoUrl))
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
            
            // Call the completion handler only on the first request, subsequent requests will update the album
            if let completionHandler = completionHandler {
                completionHandler(nil)
            } else {
                NotificationCenter.default.post(name: AlbumManagerNotificationName.albumsWereAdded, object: albumAdditions)
            }
        }
    }
}

extension FacebookAlbumManager: AlbumManager {
    
    func loadAlbums(completionHandler: ((Error?) -> Void)?) {
        guard albums.isEmpty else {
            completionHandler?(nil)
            return
        }
        
        fetchAlbums(graphPath: Constants.graphPath, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAlbums(completionHandler: ((Error?) -> Void)?) {
        guard let after = after else { return }
        let graphPath = Constants.graphPath + "&after=\(after)"
        fetchAlbums(graphPath: graphPath, completionHandler: completionHandler)
    }
    
    var hasMoreAlbumsToLoad: Bool {
        return after != nil
    }    
}

extension FacebookAlbumManager: PickerAnalytics {
    var addingMorePhotosScreenName: Analytics.ScreenName { return .facebookAlbumsAddingMorePhotos }
    var selectingPhotosScreenName: Analytics.ScreenName { return .facebookAlbums }
}
