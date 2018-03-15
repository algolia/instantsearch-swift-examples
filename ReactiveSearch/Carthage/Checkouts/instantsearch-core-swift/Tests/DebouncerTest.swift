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

@testable import InstantSearchCore
import XCTest


class DebouncerTest: CallerTest {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDefault() {
        let expectation = self.expectation(description: #function)
        let delay = 0.3
        let throttler = Debouncer(delay: delay)
        let callDelays: [TimeInterval] = [
            0.1, // #0
            0.2, // #1
            0.3, // #2
            0.4, // #3
            0.5, // #4: fired
            // 0.8 = call #4 fired
            0.9, // #5
            1.0, // #6
            1.1, // #7: fired
            // 1.4 = call #7 fired
            1.5, // #8
            // 1.8: call #8 fired
        ]
        checkIterations(caller: throttler, callDelays: callDelays, callsToBeFired: [4, 7, 8], expectation: expectation)
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
