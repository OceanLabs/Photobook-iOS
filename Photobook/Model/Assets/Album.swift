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

/// Collection of Assets
protocol Album {
    
    // Identifier
    var identifier: String { get }

    /// Number of Assets in the album
    var numberOfAssets: Int { get }
    
    /// Localized name
    var localizedName: String? { get }
    
    /// Collection of already loaded Assets
    var assets: [Asset] { get }
    
    /// True if the album has more Assets to load, False otherwise
    var hasMoreAssetsToLoad: Bool { get }
    
    /// Performs the loading of a first batch of Assets
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadAssets(completionHandler: ((_ error: Error?) -> Void)?)
    
    /// Performs the loading of the next batch of Assets
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadNextBatchOfAssets(completionHandler: ((_ error: Error?) -> Void)?)
    
    /// Retrieves the Asset to be used as cover for the Album
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func coverAsset(completionHandler: @escaping (_ asset: Asset?) -> Void)
}

struct AlbumChange {
    var album: Album
    var assetsRemoved: [Asset]
    var indexesRemoved: [Int]
    var assetsInserted: [Asset]
}

struct AlbumAddition {
    var album: Album
    var index: Int
}
