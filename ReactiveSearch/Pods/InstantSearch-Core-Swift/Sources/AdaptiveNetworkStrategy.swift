//
//  Copyright (c) 2016-2017 Algolia
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
import Foundation


/// Request strategy that adapts to the current network conditions.
///
/// This strategies switches between three modes, depending on reponse time statistics:
///
/// - **Realtime**: all requests are fired immediately.
/// - **Throttled**: requests are throttled to avoid firing too many. The throttling rate is dynamically adjusted to
///   the current response time.
/// - **Manual**: all non-final searches are discarded.
///
/// A **final** search is a call to the `search(...)` method with the final flag set to `true` in the `userInfo`
/// (see `Searcher.notificationIsFinalKey`). This will bypass the strategy altogether and fire the request immediately.
///
/// + Warning: The manual mode requires user feedback: typically, the application should display a message like
///   "Press 'Search' to see results". Then, when the user presses the "Search" button, the application should fire a
///   final search.
///
/// To decide between modes, the strategy relies on two thresholds: `throttleThreshold` and `manualThreshold`. If the
/// response time goes above either of them, the corresponding mode will be activated. Of course, you should ensure
/// that `throttleThreshold` is less than `manualThreshold`.
///
@objc public class AdaptiveNetworkStrategy: NSObject, RequestStrategy {

    // MARK: Types
    
    /// Possible search nodes.
    @objc(DefaultRequestStrategyMode)
    public enum Mode: Int {
        /// As-you-type search in realtime: every keystroke immediately triggers a request.
        case Realtime = 1
        
        /// As-you-type search with throttling: requests are slightly delayed and merged if necessary, to avoid spawning
        /// too many of them.
        case Throttled = 2
        
        /// Search has to be explicitly triggered by the user.
        case Manual = 3
    }

    // ----------------------------------------------------------------------
    // MARK: - Properties
    // ----------------------------------------------------------------------

    /// Current throttle delay. This is dynamically adjusted from the observed response time.
    @objc public private(set) var throttleDelay: TimeInterval = 0.5 {
        didSet {
            for throttler in throttlers.objectEnumerator()!.allObjects as! [Throttler] {
                throttler.delay = throttleDelay
            }
        }
    }
    
    /// Throttlers used in throttled mode.
    /// There must be one throttler per searcher, otherwise results of throttling will be inconsistent.
    /// The keys are defined as weak to prevent memory cycles.
    ///
    private var throttlers: NSMapTable<Searcher, Throttler> = NSMapTable<Searcher, Throttler>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    /// Maximum number of requests from the statistics that will be considered.
    @objc public var windowSize: Int = 5

    /// Threshold beyond which throttled mode is activated.
    @objc public var throttleThreshold: TimeInterval = 0.5 {
        didSet {
            updateTriggers()
        }
    }
    
    /// Threshold beyond which manual mode is activated.
    @objc public var manualThreshold: TimeInterval = 3.0 {
        didSet {
            updateTriggers()
        }
    }
    
    /// The current strategy.
    ///
    /// + Note: KVO-observable.
    ///
    @objc public private(set) var mode: Mode = .Realtime {
        willSet(newValue) {
            if newValue != mode {
                self.willChangeValue(forKey: "mode")
            }
        }
        didSet(oldValue) {
            if oldValue != mode {
                #if DEBUG
                    NSLog("New strategy: \(mode.rawValue)")
                #endif
                self.didChangeValue(forKey: "mode")
                NotificationCenter.default.post(name: AdaptiveNetworkStrategy.ModeSwitchNotification, object: self)
            }
        }
    }
    
    /// Response time statistics used to decide between strategies.
    @objc public let stats: ResponseTimeStats
    
    // ----------------------------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------------------------
    
    /// Construct a new strategy using the specified statistics.
    ///
    @objc public init(stats: ResponseTimeStats) {
        self.stats = stats
        super.init()
        updateTriggers()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStrategy), name:ResponseTimeStats.UpdateNotification, object: stats)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Update the response time statistics triggers to match this strategy's thresholds.
    ///
    private func updateTriggers() {
        stats.triggerDelays = [throttleThreshold, manualThreshold]
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Search
    // ----------------------------------------------------------------------
    
    /// Perform a search on behalf of a searcher.
    ///
    /// - parameter searcher: Searcher asking for the search.
    /// - parameter userInfo: Search metadata, as passed to `Searcher.search(...)`. This strategy only uses the
    ///                       final flag.
    /// - parameter callback: Block to be called to perform the search.
    ///
    @objc public func performSearch(from searcher: Searcher, userInfo: [String: Any], with callback: @escaping ([String: Any]) -> Void) {
        let isFinal = userInfo[Searcher.userInfoIsFinalKey] as? Bool ?? false
        if isFinal {
            callback(userInfo)
        } else {
            updateStrategy()
            switch mode {
            case .Realtime:
                callback(userInfo)
                break
            case .Throttled:
                throttler(for: searcher).call({
                    callback(userInfo)
                })
                break
            case .Manual:
                // Inform observers that a request has been dropped.
                NotificationCenter.default.post(name: AdaptiveNetworkStrategy.DropNotification, object: self, userInfo: nil)
                break
            }
        }
    }
    
    private func throttler(for searcher: Searcher) -> Throttler {
        if let throttler = throttlers.object(forKey: searcher) {
            return throttler
        } else {
            let throttler = Throttler(delay: throttleDelay)
            throttlers.setObject(throttler, forKey: searcher)
            return throttler
        }
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Events
    // ----------------------------------------------------------------------
   
    /// Update the strategy based on the current stats.
    @objc private func updateStrategy() {
        let requests = stats.requestStats
        
        // Compute average duration
        // ------------------------
        // We have a dilemma here:
        // - Short non-completed requests (still running or cancelled) do not mean the response time is good...
        // - ... but long non-completed requests do mean that the response time is bad!
        //
        // => We compute two values, (1) for completed requests and (2) for all requests, and take the worst one.
        //
        let overallStats = requests.suffix(windowSize)
        let completedStats = requests.filter({ $0.completed }).suffix(windowSize)
        func avg(_ slice: ArraySlice<ResponseTimeStats.RequestStat>) -> TimeInterval {
            return slice.isEmpty ? 0.0 : slice.reduce(0.0) { $0 + $1.duration } / Double(slice.count)
        }
        let overallAverageDuration = avg(overallStats)
        let completedAverageDuration = avg(completedStats)
        let worstAverageDuration = max(overallAverageDuration, completedAverageDuration)
        
        let lastDuration = requests.last?.duration ?? 0.0
        let lastCompleted = requests.last?.completed ?? false
        #if DEBUG
            NSLog("Request history: \(stats)")
            NSLog("AVG: overall=\(overallAverageDuration), completed=\(completedAverageDuration); LAST: \(lastDuration)")
        #endif
        
        // Choose the strategy
        // -------------------
        // NOTE: One last good duration is enough to consider that realtime conditions are back. This optimistic
        // algorithm allows to react immediately when good network is back.
        //
        // CAUTION: Non-completed requests do no count.
        //
        if (lastCompleted && lastDuration < throttleThreshold) || worstAverageDuration < throttleThreshold {
            mode = .Realtime
        }
        // Otherwise, if average duration is within acceptable bounds, use throttled mode.
        else if worstAverageDuration < manualThreshold {
            mode = .Throttled
            throttleDelay = max(completedAverageDuration, throttleThreshold)
        }
        // Out of desperation, revert to manual mode.
        else {
            mode = .Manual
        }
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Notifications
    // ----------------------------------------------------------------------

    /// Notification posted when the mode has been updated.
    ///
    /// + Note: You can also observe the `mode` property through KVO.
    ///
    @objc public static let ModeSwitchNotification = Notification.Name("modeSwitch")
    
    /// Notification posted when a request is dropped (only occurs in `Manual` strategy).
    @objc public static let DropNotification = Notification.Name("drop")
}
