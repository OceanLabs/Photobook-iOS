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
import Photobook
import FBSDKLoginKit

protocol FacebookApiManager {
    var accessToken: String? { get }
    func request(withGraphPath path: String, parameters: [String: Any]?, completion: @escaping (Any?, Error?) -> Void)
}

class DefaultFacebookApiManager: FacebookApiManager {
    var accessToken: String? {
        return AccessToken.current?.tokenString
    }
    func request(withGraphPath path: String, parameters: [String : Any]?, completion: @escaping (Any?, Error?) -> Void) {
        let graphRequest = GraphRequest(graphPath: path, parameters: parameters ?? [:])
        _ = graphRequest.start { _, result, error in
            completion(result, error)
        }
    }
}

class FacebookAlbum: Codable {
    
    private struct Constants {
        static let pageSize = 100
        static let serviceName = "Facebook"
    }
    
    var numberOfAssets: Int
    var localizedName: String?
    var identifier: String
    var assets = [PhotobookAsset]()
    var coverPhotoUrl: URL
    private var after: String?
    
    var graphPath: String {
        return "\(identifier)/photos?fields=picture,source,id,images&limit=\(Constants.pageSize)"
    }
    
    lazy var facebookManager: FacebookApiManager = DefaultFacebookApiManager()

    init(identifier: String, localizedName: String, numberOfAssets: Int, coverPhotoUrl: URL) {
        self.identifier = identifier
        self.localizedName = localizedName
        self.numberOfAssets = numberOfAssets
        self.coverPhotoUrl = coverPhotoUrl
    }
    
    private enum CodingKeys: String, CodingKey {
        case identifier, localizedName, numberOfAssets, coverPhotoUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(localizedName, forKey: .localizedName)
        try container.encode(numberOfAssets, forKey: .numberOfAssets)
        try container.encode(coverPhotoUrl, forKey: .coverPhotoUrl)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try values.decode(String.self, forKey: .identifier)
        localizedName = try values.decode(String.self, forKey: .localizedName)
        numberOfAssets = try values.decode(Int.self, forKey: .numberOfAssets)
        coverPhotoUrl = try values.decode(URL.self, forKey: .coverPhotoUrl)
        
        loadAssets(completionHandler: nil)
    }
    
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
            
            var newAssets = [PhotobookAsset]()
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
                
                if let newAsset = PhotobookAsset(withUrlImages: urlAssetImages, identifier: identifier, albumIdentifier: self.identifier, date: nil) {
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
    
    func coverAsset(completionHandler: @escaping (PhotobookAsset?) -> Void) {
        let asset = PhotobookAsset(withUrlImages: [URLAssetImage(url: coverPhotoUrl, size: .zero)], identifier: coverPhotoUrl.absoluteString, albumIdentifier: identifier, date: nil)
        completionHandler(asset)
    }
}

extension FacebookAlbum: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .facebookPicker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .facebookPickerAddingMorePhotos }
}
