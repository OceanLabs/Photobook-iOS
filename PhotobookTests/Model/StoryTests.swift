//
//  StoryTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook
import Photos

class PHCollectionListMock: PHCollectionList {
    
    var startDateStub: Date?
    var endDateStub: Date?
    
    override var localizedTitle: String? {
        return "Collection1"
    }
    
    override var startDate: Date? {
        return startDateStub
    }
    
    override var endDate: Date? {
        return endDateStub
    }
}

class StoryTests: XCTestCase {
    
    var story: Story!
    var list = PHCollectionListMock()
    var coverCollection = PHAssetCollection()
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    override func setUp() {
        super.setUp()
        
        story = Story(list: list, coverCollection: coverCollection)
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
    
    func testTitleShouldBeTheUppercasedCollectionsTitle() {
        XCTAssertEqual(story.title, story.collectionList.localizedTitle!.uppercased(), "Should have an uppercased title")
    }
    
    func testSubtitleIsCorrectForASingleDay() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        (story.collectionList as! PHCollectionListMock).startDateStub = startDate
        (story.collectionList as! PHCollectionListMock).endDateStub = startDate
        
        XCTAssert(story.subtitle ==  "NOV 1, 2017" || story.subtitle ==  "1 NOV 2017", "The subtitle should be 'NOV 1, 2017' or '1 NOV 2017' depending on locale, was: \(story.subtitle!)")
    }
    
    func testSubtitleIsCorrectForASameMonthDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .day, value: 5, of: startDate!)
        
        (story.collectionList as! PHCollectionListMock).startDateStub = startDate
        (story.collectionList as! PHCollectionListMock).endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV 2017", "The subtitle should be 'NOV 2017'")
    }

    func testSubtitleIsCorrectForDifferentMonthDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .month, value: 12, of: startDate!)
        
        (story.collectionList as! PHCollectionListMock).startDateStub = startDate
        (story.collectionList as! PHCollectionListMock).endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV - DEC 2017", "The subtitle should be 'NOV - DEC 2017'")
    }
    
    func testSubtitleIsCorrectForDifferentYearDates() {
        // Test with same date
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        startComponents.year = 2018
        let endDate = calendar.date(from: startComponents)
        
        (story.collectionList as! PHCollectionListMock).startDateStub = startDate
        (story.collectionList as! PHCollectionListMock).endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "NOV 2017 - NOV 2018", "The subtitle should be 'NOV 2017 - NOV 2018'")
    }

    func testSubtitleIsCorrectForAWeekekEnd() {
        // The dates themselves are not relevant to determine if it is a weekend
        story.isWeekend = true
        
        var startComponents = DateComponents()
        startComponents.day = 1; startComponents.month = 11; startComponents.year = 2017
        let startDate = calendar.date(from: startComponents)
        
        let endDate = calendar.date(bySetting: .day, value: 3, of: startDate!)

        (story.collectionList as! PHCollectionListMock).startDateStub = startDate
        (story.collectionList as! PHCollectionListMock).endDateStub = endDate
        
        XCTAssertEqual(story.subtitle, "WEEKEND IN NOV 2017", "The subtitle should be 'WEEKEND IN NOV 2017")
    }
}
