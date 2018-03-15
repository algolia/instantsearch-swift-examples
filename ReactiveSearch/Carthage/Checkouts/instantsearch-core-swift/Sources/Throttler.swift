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

import Foundation


/// Ensures a maximum throughput on a stream of calls.
/// The throughput is expressed as a minimum delay between calls, via the `delay` property.
///
@objc public class Throttler: NSObject, Caller {
    
    // ----------------------------------------------------------------------
    // MARK: - Properties
    // ----------------------------------------------------------------------
    
    /// Minimum delay between two calls.
    @objc public var delay: TimeInterval {
        didSet {
            // Update the timer if needed.
            if self.timer != nil {
                initTimer()
            }
        }
    }
    
    /// Whether to fire immediately the initial call in a series. Default = `true`.
    ///
    /// A series begins when a call is enqueued, and ends when the `delay` expires without any call being fired.
    /// When this property is true, the initial call in a series will be fired immediately; subsequent calls will be
    /// enqueued for deferred firing. When it is false, all calls are enqueued, including the initial call.
    ///
    @objc public var fireInitialCall: Bool = true
    
    /// The next call to fire.
    private var pendingCall: Caller.Call!
    
    /// Timer used to fire the calls.
    /// For performance reasons, it is only activated when and as long as necessary.
    private var timer: Timer?
    
    // ----------------------------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------------------------
    
    /// Init a throttler with a given delay.
    ///
    /// - parameter delay: The minimum delay between two calls.
    ///
    @objc public init(delay: TimeInterval) {
        self.delay = delay
        super.init()
    }
    
    deinit {
        timer?.invalidate()
    }

    /// Setup the timer.
    /// It will be created if necessary, or replaced if already existing.
    ///
    private func initTimer() {
        // NOTE: If there already is a running timer, we want to preserve the next fire date.
        // CAUTION: In some cases, the `fireDate` property may give the *last* fired date (instead of the next one).
        let now = Date()
        let fireDate = timer == nil ? now + delay : (timer!.fireDate > now ? timer!.fireDate : timer!.fireDate + delay)
        timer?.invalidate()
        timer = Timer(fireAt: fireDate, interval: delay, target: self, selector: #selector(self.runBlock), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
    }

    /// Remove the timer.
    private func deinitTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Scheduling calls
    // ----------------------------------------------------------------------
    
    /// Register another call.
    /// It may be eventually fired or not, depending on the throttler's policy and current state.
    ///
    /// - parameter block: The call to throttle.
    ///
    @objc public func call(_ block: @escaping Caller.Call) {
        let isInitialCall = self.pendingCall == nil && self.timer == nil

        // Start a series if needed.
        if self.timer == nil {
            initTimer()
        }
        // Fire immediately if first in its series and the policy allows it.
        if isInitialCall && self.fireInitialCall {
            block()
        }
        // Otherwise, schedule for firing later.
        else {
            self.pendingCall = block
        }
    }
    
    @objc private func runBlock() {
        if self.pendingCall == nil { // series has ended
            deinitTimer()
        } else {
            self.pendingCall()
            pendingCall = nil
        }
    }
}
