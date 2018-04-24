//
//  ViewController.swift
//  SDK Demo
//
//  Created by Konstadinos Karayannis on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PhotobookSDK

let baseImageURL = "https://s3.amazonaws.com/psps/sdk_static/"

let sizes: [Int: CGSize] = [1: CGSize(width: 1824, height: 1216), 10: CGSize(width: 3456, height: 2592), 11: CGSize(width: 2494, height: 1927), 12: CGSize(width: 3210, height: 2167), 13: CGSize(width: 2400, height: 1818), 14: CGSize(width: 2359, height: 2268), 15: CGSize(width: 2683, height: 2012), 16: CGSize(width: 3456, height: 2592), 17: CGSize(width: 5616, height: 3744), 18: CGSize(width: 2942, height: 2448), 19: CGSize(width: 1822, height: 2448), 2: CGSize(width: 612, height: 612), 20: CGSize(width: 2345, height: 1465), 21: CGSize(width: 3264, height: 2448), 22: CGSize(width: 3264, height: 2414), 23: CGSize(width: 3264, height: 2448), 24: CGSize(width: 5184, height: 3456), 25: CGSize(width: 3264, height: 2448), 26: CGSize(width: 1391, height: 1043), 27: CGSize(width: 3465, height: 2578), 28: CGSize(width: 2400, height: 1648), 29: CGSize(width: 3264, height: 2448), 3: CGSize(width: 843, height: 960), 30: CGSize(width: 2400, height: 1660), 31: CGSize(width: 3153, height: 2225), 32: CGSize(width: 4928, height: 3264), 33: CGSize(width: 2356, height: 1754), 34: CGSize(width: 5184, height: 3456), 35: CGSize(width: 4928, height: 3264), 36: CGSize(width: 5184, height: 3456), 37: CGSize(width: 4928, height: 3264), 38: CGSize(width: 4928, height: 3264), 39: CGSize(width: 2400, height: 1712), 4: CGSize(width: 1034, height: 1034), 40: CGSize(width: 3056, height: 2135), 41: CGSize(width: 3029, height: 2559), 42: CGSize(width: 2400, height: 1710), 43: CGSize(width: 5152, height: 3864), 44: CGSize(width: 4252, height: 2816), 45: CGSize(width: 2957, height: 4435), 46: CGSize(width: 2633, height: 2040), 47: CGSize(width: 5184, height: 3456), 48: CGSize(width: 4175, height: 2783), 49: CGSize(width: 1800, height: 1199), 5: CGSize(width: 2048, height: 1362), 50: CGSize(width: 4288, height: 2848), 6: CGSize(width: 2048, height: 1152), 7: CGSize(width: 1600, height: 1144), 8: CGSize(width: 1882, height: 2509), 9: CGSize(width: 3264, height: 2448)]

class ViewController: UIViewController {

    @IBAction func createPhotobookWithWebPhotos(_ sender: Any) {
        var assets = [URLAsset]()
        for imageNumber in 1...50 {
            assets.append(URLAsset(URL(string: baseImageURL+"\(imageNumber).jpg")!, size: sizes[imageNumber]!))
        }
        
        PhotobookSDK.shared.setEnvironment(environment: .test)
        PhotobookSDK.shared.kiteApiKey = "78b798ff366815c833dfa848654aba43b71a883a"
        
        guard let photobookVc = PhotobookSDK.shared.photobookViewController(with: assets) else { return }
        
        present(photobookVc, animated: true, completion: nil)
    }

}

