//
//  DiskUtils.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 19/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DiskUtils {
    
    private struct Storage {
        static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    static func saveDataToCachesDirectory(data: Data, name: String) -> URL? {
        let fileUrl = Storage.cachesDirectory.appendingPathComponent(name)
        do {
            try data.write(to: fileUrl)
            return fileUrl
        } catch {
            print(error)
            return nil
        }
    }

}
