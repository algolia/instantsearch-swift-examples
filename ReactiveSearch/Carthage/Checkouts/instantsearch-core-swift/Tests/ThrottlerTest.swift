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


class ThrottlerTest: CallerTest {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDefault() {
        let expectation = self.expectation(description: #function)
        let delay = 0.5
        let throttler = Throttler(delay: delay)
        let callDelays: [TimeInterval] = [
            0.1, // #0: fired
            0.2, // #1
            0.3, // #2
            0.4, // #3: fired
            // 0.6 = delay after 1st call
            0.7, // #4
            0.8, // #5
            0.9, // #6
            1.0, // #7: fired
            // 1.1 = delay after 2nd call
            1.3, // #8
            1.4  // #9: last always fired
        ]
        checkIterations(caller: throttler, callDelays: callDelays, callsToBeFired: [0, 3, 7, 9], expectation: expectation)
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testNoInitialCall() {
        let expectation = self.expectation(description: #function)
        let delay = 0.5
        let throttler = Throttler(delay: delay)
        throttler.fireInitialCall = false
        let callDelays: [TimeInterval] = [
            0.1, // #0: absorbed
            0.2, // #1
            0.3, // #2
            0.4, // #3: fired
            // 0.6 = delay after 1st call
            0.7, // #4
            0.8, // #5
            0.9, // #6
            1.0, // #7: fired
            // 1.1 = delay after 2nd call
            1.3, // #8
            1.4  // #9: last always fired
        ]
        checkIterations(caller: throttler, callDelays: callDelays, callsToBeFired: [3, 7, 9], expectation: expectation)
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
