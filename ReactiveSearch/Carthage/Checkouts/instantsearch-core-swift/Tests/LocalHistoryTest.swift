//
//  Copyright (c) 2017 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
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

import AlgoliaSearch
@testable import InstantSearchCore
import XCTest


class LocalHistoryTest: XCTestCase {
    var history: LocalHistory!
    
    override func setUp() {
        super.setUp()
        history = LocalHistory()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testNormalization() {
        let params = SearchParameters()

        // Lowercase.
        params.query = "MiXed CaSE"
        history.add(params)
        XCTAssertEqual(history.contents, ["mixed case"])
        history.clear()

        // Whitespace trimming.
        params.query = "\t white    space \n\r"
        history.add(params)
        XCTAssertEqual(history.contents, ["white space"])
    }

    func testLRU() {
        let params = SearchParameters()
        
        params.query = "first"
        history.add(params)
        XCTAssertEqual(history.contents, ["first"])
        
        params.query = "second"
        history.add(params)
        XCTAssertEqual(history.contents, ["second", "first"])

        params.query = "first"
        history.add(params)
        XCTAssertEqual(history.contents, ["first", "second"])
    }

    func testEviction() {
        history.maxCount = 3
        let params = SearchParameters()
        
        params.query = "one"
        history.add(params)
        XCTAssertEqual(history.contents, ["one"])
        
        params.query = "two"
        history.add(params)
        XCTAssertEqual(history.contents, ["two", "one"])
        
        params.query = "three"
        history.add(params)
        XCTAssertEqual(history.contents, ["three", "two", "one"])

        params.query = "four"
        history.add(params)
        XCTAssertEqual(history.contents, ["four", "three", "two"])
    }
    
    func testEliminateRedundancy() {
        let params = SearchParameters()
        
        params.query = "star"
        history.add(params)
        XCTAssertEqual(history.contents, ["star"])
        
        // Prefix should be rejected.
        params.query = "st"
        history.add(params)
        XCTAssertEqual(history.contents, ["star"])

        // Non-prefix should be added.
        params.query = "alien"
        history.add(params)
        XCTAssertEqual(history.contents, ["alien", "star"])
        
        // Suffix ending on word boundary should be added.
        params.query = "star wars"
        history.add(params)
        XCTAssertEqual(history.contents, ["star wars", "alien", "star"])
    
        // Suffix should replace existing entry.
        params.query = "stars"
        history.add(params)
        XCTAssertEqual(history.contents, ["stars", "star wars", "alien"])
    }

    func testSearch() {
        let params = SearchParameters()
        
        params.query = "Star Wars"
        history.add(params)
        params.query = "War Games"
        history.add(params)
        params.query = "Thwart the Unaware Awards" // contains "war", but not as word prefix
        history.add(params)
        
        params.query = "war"
        var hits = history.search(query: params)
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(hits[0].params.query, "war games")
        XCTAssertEqual(hits[0].highlightedText, "<em>war</em> games")
        XCTAssertEqual(hits[1].params.query, "star wars")
        XCTAssertEqual(hits[1].highlightedText, "star <em>war</em>s")
        
        let options = HistorySearchOptions()

        hits = history.search(query: params, options: options)
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(hits[0].params.query, "war games")
        XCTAssertEqual(hits[0].highlightedText, "<em>war</em> games")
        XCTAssertEqual(hits[1].params.query, "star wars")
        XCTAssertEqual(hits[1].highlightedText, "star <em>war</em>s")

        options.highlightPreTag = "<mark>"
        options.highlightPostTag = "</mark>"
        hits = history.search(query: params, options: options)
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(hits[0].params.query, "war games")
        XCTAssertEqual(hits[0].highlightedText, "<mark>war</mark> games")
        XCTAssertEqual(hits[1].params.query, "star wars")
        XCTAssertEqual(hits[1].highlightedText, "star <mark>war</mark>s")

        options.maxHits = 1
        hits = history.search(query: params, options: options)
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits[0].params.query, "war games")
        XCTAssertEqual(hits[0].highlightedText, "<mark>war</mark> games")
    }
    
    func testPersistence() {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("history.plist").path
        let params = SearchParameters()
        
        params.query = "xyz"
        history.add(params)
        params.query = "abc def"
        history.add(params)
        XCTAssertEqual(history.contents, ["abc def", "xyz"])
        history.filePath = filePath
        history.save()

        let history2 = LocalHistory(filePath: filePath)
        XCTAssertEqual(history2.contents, ["abc def", "xyz"])
    }
}
