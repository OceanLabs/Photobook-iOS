//
//  UIScreenExtensions.swift
//  Kite-SDK
//
//  Created by Konstadinos Karayannis on 31/10/2017.
//  Copyright © 2017 Kite. All rights reserved.
//

import UIKit

extension UIScreen {
    
    
    /// The iPhone 6 Plus, aka "iPhone7,1", only had 1GB or RAM which was inadequate for it's @3x screen. For that device resize the images to @2x scale. They don't look too bad anyway, and anything is better than crashing.
    /// C system calls in Swift take from https://stackoverflow.com/a/27759550/3265861
    ///
    /// - Returns: The usable screen scale. It will be UIScreen.main.scale for all devices but the 6 Plus.
    func usableScreenScale() -> CGFloat{
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
                
            }
        }
        if modelCode == "iPhone7,1"{
            return 2.0
        }
        
        return UIScreen.main.scale
    }
}
