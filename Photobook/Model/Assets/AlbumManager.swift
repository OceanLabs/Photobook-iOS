//
//  AlbumManager
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol AlbumManager {
    var albums:[Album] { get }
    
    func loadAlbums(completionHandler: ((_ error: Error?) -> Void)?)
}
