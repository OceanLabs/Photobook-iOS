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

import XCTest
import Photos
@testable import Photobook_App
@testable import Photobook

class StoryTests: XCTestCase {
    
    var story: Story!
    var list = PHCollectionListMock()
    var coverCollection = PHAssetCollection()
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    override func setUp() {
        super.setUp()
        
        story = Story(list: list, storyTitle: list.localizedTitle!, coverCollection: coverCollection)
    }
    
    override func tearDown() {
        story.isWeekend = false
        super.tearDown()
    }
    
    func testAStoryCanBeCreated() {
        XCTAssertNotNil(story, "Should be able to create a Story")
    }
    
    func testTheCollectionListIsStored() {
        XCTAssertEqual(story.collectionList.localIdentifier, list.localIdentifier, "Should have stored the collection list")
    }
    
    func testTheCoverCollectionIsStored() {
        XCTAssertEqual(story.collectionForCoverPhoto.localIdentifier, coverCollection.localIdentifier, "Should have stored the collection for the cover")
    }
    
    func testShouldBeAbleToAssignComponents() {
        let components = [String]()
        
        story.components = components
        XCTAssertEqual(story.components, components, "Should be able to assign location components")
    }
    
    func testShouldInitialisePublicVars() {
        XCTAssertEqual(story.photoCount, 0, "Should have 0 photos")
        XCTAssertFalse(story.isWeekend, "Should not be a weekend")
        XCTAssertEqual(story.score, 0, "Should have a score of 0")
    }
    
    func testTitle_shouldBeTheUppercasedCollectionsTitle() {
        XCTAssertEqual(story.title, story.collectionList.localizedTitle!.uppercased(), "Should have an uppercased title")
    }
    
    func testSubtitle_shouldBeEmptyIfStartDateIsMissing() {
        var components = DateComponents()
        components.day = 1; components.month = 11; components.year = 2017
        let date = calendar.date(from: components)
        
        story.locale = Locale(identifier: "en_US")
        list.startDateStub = nil
        list.endDateStub = date
        
        XCTAssertTrue(story.subtitle != nil && story.subtitle!.isEmpty)
    }

    func testSubtitle_shouldBeEmptyIfEndDateIsMissing() {
        var components = DateComponents()
        components.day = 1; components.month = 11; components.year = 2017
        let date = calendar.date(from: components)
        
        story.locale = Locale(identifier: "en_US")
        list.startDateStub = date
        list.endDateStub = nil
        
        XCTAssertTrue(story.subtitle != nil && story.subtitle!.isEmpty)
    }

    func testSubtitle_isCorrectForASingleDay() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        story.locale = Locale(identifier: "en_US")
        list.startDateStub = startDate
        list.endDateStub = startDate
        
        XCTAssert(story.subtitle ==  "NOV 1, 2017", "The subtitle should be 'NOV 1, 2017' but was: \(story.subtitle!)")
    }
    
    func testSubtitle_isCorrectForASameMonthDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .day, value: 5, of: startDate!)
        list.startDateStub = startDate
        list.endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV 2017", "The subtitle should be 'NOV 2017'")
    }

    func testSubtitle_isCorrectForDifferentMonthDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .month, value: 12, of: startDate!)
        
        list.startDateStub = startDate
        list.endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV - DEC 2017", "The subtitle should be 'NOV - DEC 2017'")
    }
    
    func testSubtitle_isCorrectForDifferentYearDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        startComponents.year = 2018
        let endDate = calendar.date(from: startComponents)
        
        list.startDateStub = startDate
        list.endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV 2017 - NOV 2018", "The subtitle should be 'NOV 2017 - NOV 2018'")
    }

    func testSubtitle_isCorrectForAWeekekEnd() {
        // The dates themselves are not relevant to determine if it is a weekend
        story.isWeekend = true
        
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .day, value: 3, of: startDate!)

        list.startDateStub = startDate
        list.endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "WEEKEND IN NOV 2017", "The subtitle should be 'WEEKEND IN NOV 2017")
    }
    
    func testLoadAssets_shouldDoNothingIfAlreadyLoaded() {
        story.assets = [PhotobookAsset(asset: PhotosAssetMock())!] 
        
        var called = false
        story.loadAssets { _ in
            called = true
        }
        XCTAssertTrue(called)
        XCTAssertEqual(story.assets.count, 1)
    }
    
    func testLoadAssets_shouldAddAssetsFromEachCollectionInTheMoment() {
        var assets = [PHAssetMock]()
        var assetCollections = [PHAssetCollectionMock]()
        for i in 0 ..< 10 {
            let assetCollection = PHAssetCollectionMock()
            assetCollection.localIdentifierStub = "collection\(i)"
            assetCollection.listIdentifier = list.localIdentifier
            assetCollections.append(assetCollection)

            for j in 0 ..< 5 {
                let asset = PHAssetMock()
                asset.localIdentifierStub = "asset\(j)"
                asset.listIdentifier = assetCollection.localIdentifier
                assets.append(asset)
            }
        }

        let testCollectionManager = CollectionManagerMock()
        testCollectionManager.phAssetCollectionStub = assetCollections
        story.collectionManager = testCollectionManager
        
        let testAssetManager = AssetManagerMock()
        testAssetManager.phAssetsStub = assets
        story.assetsManager = testAssetManager
        
        story.loadAssets { _ in
            XCTAssertEqual(self.story.assets.count, 50)
        }
    }

}
