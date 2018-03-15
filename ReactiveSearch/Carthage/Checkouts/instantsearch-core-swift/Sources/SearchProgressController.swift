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


/// Delegate to a `SearchProgressController`.
///
@objc public protocol SearchProgressDelegate {
    /// Fired when progress should start being reported.
    @objc func searchDidStart(_ searchProgressController: SearchProgressController)
    
    /// Fired when progress should stop being reported.
    @objc func searchDidStop(_ searchProgressController: SearchProgressController)
}


/// Tracks progress of a `Searcher`.
///
/// This class has a delegate (`SearchProgressDelegate`) that will be informed of progress events; it does not update
/// any widget directly. As a consequence, it is toolkit-agnostic (e.g. can work with both UIKit or AppKit).
///
/// By default, search requests are notified immediately. However, you may introduce a **grace delay** through the
/// `graceDelay` property: any request returning in less than this delay will not cause start/stop events to be fired.
///
@objc public class SearchProgressController: NSObject {
    // MARK: Properties
    
    /// Searcher monitored by this progress controller.
    @objc public let searcher: Searcher
    
    /// Delegate to this progress controller.
    @objc public weak var delegate: SearchProgressDelegate?
    
    /// Delay before which search requests are not reported. Default: 0, meaning requests are reported immediately.
    /// When this is non-zero, fast enough requests do not trigger any event.
    @objc public var graceDelay: TimeInterval = 0
    
    /// Whether a search is currently advertised as running.
    @objc public private(set) var running: Bool = false {
        didSet(wasRunning) {
            if running && !wasRunning {
                delegate?.searchDidStart(self)
            } else if !running && wasRunning {
                delegate?.searchDidStop(self)
            }
        }
    }
    
    /// Timer used to start the activity indicator after a delay.
    private var activityIndicatorTimer: Timer?
    
    // MARK: - Initialization
    
    @objc public init(searcher: Searcher) {
        self.searcher = searcher
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRunning), name: Searcher.SearchNotification, object: searcher)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRunning), name: Searcher.ResultNotification, object: searcher)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRunning), name: Searcher.ErrorNotification, object: searcher)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateRunning), name: Searcher.CancelNotification, object: searcher)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Update the running state.
    @objc private func updateRunning(notification: NSNotification) {
        if !searcher.hasPendingRequests {
            activityIndicatorTimer?.invalidate()
            activityIndicatorTimer = nil
            running = false
        } else {
            if !running {
                // Start immediately.
                if graceDelay <= 0.0 {
                    running = true
                }
                // Start delayed.
                else {
                    if activityIndicatorTimer == nil {
                        activityIndicatorTimer = Timer.scheduledTimer(timeInterval: graceDelay, target: self, selector: #selector(self.setRunning), userInfo: nil, repeats: false)
                    }
                }
            }
        }
    }
    
    @objc private func setRunning() {
        running = true
    }
}
