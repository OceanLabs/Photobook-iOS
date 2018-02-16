//
//  AssetPickerCollectionViewController+Instagram.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import OAuthSwift

extension AssetPickerCollectionViewController: OAuthSwiftURLHandlerType {
    
    func handle(_ url: URL) {
        navigationController?.pushViewController(storyboard!.instantiateViewController(withIdentifier: "InstagramLandingViewController"), animated: true)
    }
    
    
}
