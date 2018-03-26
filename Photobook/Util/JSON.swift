//
//  Json.swift
//  Photobook
//
//  Created by Julian Gruber on 06/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class JSON {
    static func parse(file: String) -> AnyObject? {
        guard let path = PhotobookUtils.photobookBundle().path(forResource: file, ofType: "json") else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            return try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
        } catch {
            print("JSON: Could not parse file")
        }
        return nil
    }
}
