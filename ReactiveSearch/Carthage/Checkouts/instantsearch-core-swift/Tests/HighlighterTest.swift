//
//  Copyright (c) 2016 Algolia
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

public func ==(lhs: NSRange, rhs: NSRange) -> Bool {
    return lhs.location == rhs.location && lhs.length == rhs.length
}


class HighlighterTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func checkRanges(string: NSAttributedString, ranges: [NSRange: [NSAttributedStringKey: Any]]) {
        string.enumerateAttributes(in: NSMakeRange(0, string.length), options: []) { (attributes, range, shouldStop) in
            guard let expectedAttributes = ranges[range] else {
                XCTFail("Range [\(range.location), \(range.location + range.length)[ not expected")
                return
            }
            // We cannot easily compare the dictionaries because values don't necessarily conform to `Equatable`.
            // So we just verify that we have the same key set. For our purposes it's enough, because non highlighted
            // ranges will have empty attributes.
            XCTAssertEqual(Array(expectedAttributes.keys), Array(attributes.keys))
        }
    }
    
    func testRender() {
        let attributes = [NSAttributedStringKey.font: "bar"]
        let renderer = Highlighter(highlightAttrs: attributes)
        let result = renderer.render(text: "Woodstock is <em>Snoopy</em>'s friend")
        checkRanges(string: result, ranges: [
            NSMakeRange(0, 13): [:],
            NSMakeRange(13, 6): attributes,
            NSMakeRange(19, 9): [:]
        ])
    }
    
    func testCustomMarkers() {
        let attributes = [NSAttributedStringKey.font: "bar"]
        let renderer = Highlighter(highlightAttrs: attributes)
        renderer.preTag = "<mark>"
        renderer.postTag = "</mark>"
        let result = renderer.render(text: "Woodstock is <mark>Snoopy</mark>'s friend")
        checkRanges(string: result, ranges: [
            NSMakeRange(0, 13): [:],
            NSMakeRange(13, 6): attributes,
            NSMakeRange(19, 9): [:]
        ])
    }

    func testCaseSensitivity() {
        let attributes = [NSAttributedStringKey.font: "bar"]
        let renderer = Highlighter(highlightAttrs: attributes)
        renderer.caseSensitive = true
        let result = renderer.render(text: "Woodstock is <EM>Snoopy</EM>'s <em>friend</em>")
        checkRanges(string: result, ranges: [
            NSMakeRange(0, 31): [:],
            NSMakeRange(31, 6): attributes
        ])
    }
    
    func testInverse() {
        let renderer = Highlighter(highlightAttrs: [:])
        XCTAssertEqual(renderer.inverseHighlights(in: ""), "")
        XCTAssertEqual(renderer.inverseHighlights(in: "<em>everything</em>"), "everything")
        XCTAssertEqual(renderer.inverseHighlights(in: "nothing"), "<em>nothing</em>")
        XCTAssertEqual(renderer.inverseHighlights(in: "prefix <em>highlight</em>"), "<em>prefix </em>highlight")
        XCTAssertEqual(renderer.inverseHighlights(in: "<em>highlight</em> suffix"), "highlight<em> suffix</em>")
        XCTAssertEqual(renderer.inverseHighlights(in: "prefix <em>highlight</em> suffix"), "<em>prefix </em>highlight<em> suffix</em>")
        
        // Edge cases:
        XCTAssertEqual(renderer.inverseHighlights(in: "abc<em>xxx"), "<em>abc</em>xxx") // unmatched tag -> up to end of string
    }
}
