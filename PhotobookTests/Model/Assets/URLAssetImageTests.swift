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
        
        if !archiveObject(urlAssetImage, to: "URLAssetImageTests.dat") {
            print("Could not save urlAssetImage")
        }
        let urlAssetImageUnarchived = unarchiveObject(from: "URLAssetImageTests.dat") as? URLAssetImage

        XCTAssertEqualOptional(urlAssetImageUnarchived?.url, urlAssetImage.url)
        XCTAssertEqualOptional(urlAssetImageUnarchived?.size.width, urlAssetImage.size.width)
        XCTAssertEqualOptional(urlAssetImageUnarchived?.size.height, urlAssetImage.size.height)
    }
}
