//
//  ShoppingListUITests.swift
//  ShoppingListUITests
//
//  Created by Spandana Batchu on 2/21/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import XCTest

class ShoppingListUITests: XCTestCase {
    
    let app = XCUIApplication()
    let item = "Chocolates"
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddingItem() {
        //1.Set up for testing
        XCTAssertFalse(app.staticTexts[item].exists)
        
        //2.Invoke Siri
        let siri = XCUIDevice.shared.siriService
        siri.activate(voiceRecognitionText: "Add \(item) to ShoppingList")
        
        //3.Wait for Siri Response
        let predicate = NSPredicate {(_,_) -> Bool in
            sleep(5)
            return true
        }
        let siriResponseExpectation = expectation(for: predicate, evaluatedWith: siri, handler: nil)
        self.wait(for: [siriResponseExpectation], timeout: 10)
        
        //4.Confirm that app has changed to expected state
        app.launch()
        XCTAssert(app.staticTexts[item].exists)
    }
    
    func testMarkingItem() {
        //1.Ensure the item exists
        XCTAssert(app.staticTexts[item].exists)
        let cell = app.tables.cells.containing(.staticText, identifier: item).firstMatch
        let imageIdentifier = cell.children(matching: .image).firstMatch.identifier
        print(imageIdentifier)
        XCTAssert(imageIdentifier == "checkbox-inactive")
        
        //2.Invoke Siri
        let siri = XCUIDevice.shared.siriService
        siri.activate(voiceRecognitionText: "Mark \(item) as done on ShoppingList")
        
        //3.Wait for Siri
        let predicate = NSPredicate {(_,_) -> Bool in
            sleep(5)
            return true
        }
        let siriResponseExpectation = expectation(for: predicate, evaluatedWith: siri, handler: nil)
        self.wait(for: [siriResponseExpectation], timeout: 10)
        
        //4.Confirm that app has changed to expected state
        app.launch()
        let newImageIdentifier = cell.children(matching: .image).firstMatch.identifier
        print(newImageIdentifier)
        XCTAssert(newImageIdentifier == "checkbox-active")
    }
    
}
