//
//  URLAssetImageTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class URLAssetImageTests: XCTestCase {
    
    func testURLAssetImage_canBeArchivedAndUnarchived() {
        
        let urlAssetImage = URLAssetImage(url: testUrl, size: testSize)
        
        guard let data = try? PropertyListEncoder().encode(urlAssetImage) else {
            XCTFail("Should encode the URLAssetImage to data")
            return
        }
        guard archiveObject(data, to: "URLAssetImageTests.dat") else {
            XCTFail("Should save the URLAssetImage data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "URLAssetImageTests.dat") as? Data else {
            XCTFail("Should unarchive the URLAssetImage as Data")
            return
        }
        guard let unarchivedUrlAssetImage = try? PropertyListDecoder().decode(URLAssetImage.self, from: unarchivedData) else {
            XCTFail("Should decode the URLAssetImage")
            return
        }

        XCTAssertEqualOptional(unarchivedUrlAssetImage.url, urlAssetImage.url)
        XCTAssertEqualOptional(unarchivedUrlAssetImage.size.width, urlAssetImage.size.width)
        XCTAssertEqualOptional(unarchivedUrlAssetImage.size.height, urlAssetImage.size.height)
    }
}
