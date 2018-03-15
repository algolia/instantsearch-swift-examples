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


/// Gathers response time statistics from one or more searchers.
///
/// ## Usage
///
/// You first need to register one or more `Searcher` instances to record response times from. This is achieved through
/// the `add(:)` method (or just supplying a searcher at init time).
///
/// Once searchers are registered, the statistics of every recorded request can be obtained at any time via the
/// `requestStats` property. The statistics keep automatically updating, posting update notifications
/// (`UpdateNotification`) when they change.
///
/// ## Configuration
///
/// Response time statistics only make sense when they are recent. This is why this class has an **amnesia delay**
/// (configurable via the `amnesiaDelay` property): any request that is older than this delay will be discarded.
///
/// There is an upper limit to the number of requests that are kept in the statistics at any time (configurable via
/// `maxRequestsInHistory`). If it goes over this limit, the less recent requests will be discarded. This avoids
/// flooding the memory if many requests are made within a short time frame.
///
/// ## Long-running requests
///
/// By default, the statistics are updated when a request is fired and when the corresponding response is received.
/// This does not allow detecting long-running requests, which may be necessary in some use cases, e.g. to adapt to
/// suddenly degraded network conditions.
///
/// To address this concern, a set of **triggers** can be defined via the `triggerDelays` property: every time a
/// request's elapsed time passes one of these thresholds, statistics are updated again (and a notification is posted),
/// although the response has not been received yet. This allows observers to detect long-running requests and react
/// accordingly. For example, the `AdaptiveNetworkStrategy` class makes extensive use of this.
///
@objc public class ResponseTimeStats: NSObject {
    // MARK: - Types
    
    /// Statistics about a single request.
    @objc public class RequestStat: NSObject {
        /// The request's sequence number.
        @objc public let seqNo: Int
        
        /// The request's start date.
        @objc public let startDate: Date
        
        /// The request's stop date, or `nil` if the request is still running.
        @objc public fileprivate(set) var stopDate: Date? = nil
        
        /// Whether the request was cancelled.
        @objc public fileprivate(set) var cancelled: Bool = false
        
        // Dynamic properties
        // ------------------
        
        /// The request's duration.
        @objc public var duration: TimeInterval { return (stopDate ?? Date()).timeIntervalSince(startDate) }
        
        /// Whether the request is still running.
        @objc public var running: Bool { return stopDate == nil }
        
        /// Whether the request has completed, i.e. returned a response.
        @objc public var completed: Bool { return !running && !cancelled }
        
        public override var description: String {
            return "RequestStat{seqNo=\(seqNo), startDate=\(startDate), duration=\(duration), running=\(running), cancelled=\(cancelled)}"
        }
        
        @objc internal init(seqNo: Int, startDate: Date) {
            self.seqNo = seqNo
            self.startDate = startDate
        }
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Properties
    // ----------------------------------------------------------------------
    
    /// Requests older than this delay will be discarded from the statistics. Default = 20 seconds.
    @objc public var amnesiaDelay: TimeInterval = 20
    
    /// Maximum number of requests that will be considered for the statistics. Always the N most recent ones are used.
    /// Default = 100.
    @objc public var maxRequestsInHistory: Int = 100
    
    /// Delays triggering a stats update.
    /// These delays are used to detect long-running queries before they return.
    @objc public var triggerDelays: [TimeInterval] = []
    
    /// Current request statistics.
    @objc public private(set) var requestStats: [RequestStat] = []
    
    // ----------------------------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------------------------
    
    /// Construct new statistics.
    ///
    @objc public override init() {
    }
    
    /// Construct new statistics, observing the specified searcher.
    ///
    /// - parameter searcher: Searcher to be observed.
    ///
    @objc public convenience init(searcher: Searcher) {
        self.init()
        addSearcher(searcher)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Add a new searcher to these statistics.
    ///
    /// + Note: The searcher is not retained.
    ///
    /// - parameter searcher: The searcher to add.
    ///
    @objc public func addSearcher(_ searcher: Searcher) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.searchEvent), name: nil, object: searcher)
    }
    
    /// Remove a searcher from these statistics.
    ///
    /// - parameter searcher: The searcher to remove.
    ///
    @objc public func removeSearcher(_ searcher: Searcher) {
        NotificationCenter.default.removeObserver(self, name: nil, object: searcher)
    }
    
    /// Clear the request history.
    @objc public func clearHistory() {
        requestStats.removeAll()
    }
    
    // ----------------------------------------------------------------------
    // MARK: - Events
    // ----------------------------------------------------------------------
    
    /// Called on `Searcher` notifications.
    @objc private func searchEvent(notification: NSNotification) {
        guard let requestSeqNo = notification.userInfo?[Searcher.userInfoSeqNoKey] as? Int else { return }
        
        switch notification.name {
        case Searcher.SearchNotification:
            // Mark start time.
            requestStats.append(RequestStat(seqNo: requestSeqNo, startDate: Date()))
            
            // Schedule to check the request after the various thresholds.
            // Why? If the request takes a long time, we want to react *before* the response is actually received
            // (which may take many seconds in case of time out).
            let checkPendingRequestsBlock = {
                [weak self] in
                guard let this = self else { return }
                if !this.requestStats.filter({ $0.running }).isEmpty {
                    this.updateStats()
                }
            }
            for triggerDelay in triggerDelays {
                DispatchQueue.main.asyncAfter(deadline: .now() + triggerDelay, execute: checkPendingRequestsBlock)
            }
            break
            
        case Searcher.ResultNotification, Searcher.ErrorNotification, Searcher.CancelNotification:
            guard let statIndex = requestStats.index(where: { $0.seqNo == requestSeqNo }) else {
                assert(false) // should never happen
                return
            }
            requestStats[statIndex].stopDate = Date()
            // Cancelled requests are tricky: we don't know what would have been their duration.
            // We sometimes want to ignore them, sometimes not. => We store the cancelled status and let the
            // algorithm decide.
            if notification.name == Searcher.CancelNotification {
                requestStats[statIndex].cancelled = true
            }
            updateStats()
            break
            
        default:
            break // ignore
        }
    }
    
    /// Update the statistics.
    private func updateStats() {
        // Remove old stats.
        let now = NSDate()
        requestStats = requestStats.filter({ $0.running || now.timeIntervalSince($0.stopDate!) < amnesiaDelay })

        // Keep only last N.
        if requestStats.count > maxRequestsInHistory {
            requestStats = Array(requestStats.suffix(maxRequestsInHistory))
        }

        // Fire notification.
        NotificationCenter.default.post(name: ResponseTimeStats.UpdateNotification, object: self)
    }
    
    // MARK: - Notifications
    
    /// Notification posted when the statistics have been updated.
    @objc public static let UpdateNotification = Notification.Name("update")
}
