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

class SequencerTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    class DelayedOperation: Operation {
        let seqNo: Int
        let delay: Int
        let completionHandler: CompletionHandler

        // IMPORTANT: Override `Operation` properties and generate KVO notifications.
        override var isAsynchronous: Bool { return true }

        override var isFinished: Bool { return _finished }
        var _finished = false {
            willSet { self.willChangeValue(forKey: "isFinished") }
            didSet { self.didChangeValue(forKey: "isFinished") }
        }

        override var isExecuting: Bool { return _executing }
        var _executing : Bool = false {
            willSet { self.willChangeValue(forKey: "isExecuting") }
            didSet { self.didChangeValue(forKey: "isExecuting") }
        }

        init(seqNo: Int, delay: Int, completionHandler: @escaping CompletionHandler) {
            self.seqNo = seqNo
            self.delay = delay
            self.completionHandler = completionHandler
            super.init()
        }
        
        override func start() {
            NSLog("Operation #\(seqNo) START")
            _executing = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay)) {
                NSLog("Operation #\(self.seqNo) END")
                defer {
                    self._executing = false
                }
                if self.isCancelled {
                    return
                }
                self.completionHandler([:], nil)
            }
        }
        
        override func cancel() {
            super.cancel()
            _finished = true
        }
    }
    
    func testSequencing() {
        class MyDelegate: SequencerDelegate {
            let operationCount = 100
            var completedOperations = Set<Int>()
            var cancelledOperations = Set<Int>()
            var expectation: XCTestExpectation!

            func startRequest(seqNo: Int, completionHandler: @escaping CompletionHandler) -> Operation {
                let operation = DelayedOperation(seqNo: seqNo, delay: 50 + Int(arc4random() % 10) * 20, completionHandler: completionHandler)
                operation.start()
                return operation
            }
            
            func handleResponse(seqNo: Int, content: [String: Any]?, error: Error?) {
                NSLog("Operation #\(seqNo) COMPLETED")

                // Check that no callback was called for this operation.
                XCTAssertFalse(cancelledOperations.contains(seqNo))
                XCTAssertFalse(completedOperations.contains(seqNo))

                // Check that no more recent operations was marked as completed.
                XCTAssert(completedOperations.filter({ $0 > seqNo }).isEmpty)

                completedOperations.insert(seqNo)
                checkEnd()
            }
            
            func requestWasCancelled(seqNo: Int) {
                NSLog("Operation #\(seqNo) CANCELLED")

                // Check that no callback was called for this operation.
                XCTAssertFalse(cancelledOperations.contains(seqNo))
                XCTAssertFalse(completedOperations.contains(seqNo))

                cancelledOperations.insert(seqNo)
                checkEnd()
            }
            
            func checkEnd() {
                if (completedOperations.count + cancelledOperations.count == operationCount) {
                    expectation.fulfill()
                }
            }
        }
        let delegate = MyDelegate()
        delegate.expectation = self.expectation(description: #function)
        let sequencer = Sequencer(delegate: delegate)
        var delay = 0;
        for _ in 0 ..< delegate.operationCount {
            delay += 50 + Int(arc4random() % 10) * 10
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay), execute: {
                sequencer.next()
            })
        }
        self.waitForExpectations(timeout: Double(delegate.operationCount) * (0.050 + 0.100) * 2, handler: nil)
    }
}
