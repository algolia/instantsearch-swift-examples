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
import Foundation


internal protocol SequencerDelegate: class {
    /// Start the next request.
    ///
    /// - parameter seqNo: The sequence number assigned to the new request.
    /// - parameter completionHandler: Completion handler to be notified of the response.
    /// - returns: A cancellable operation.
    ///
    func startRequest(seqNo: Int, completionHandler: @escaping CompletionHandler) -> Operation
    
    /// Handle a response to a request.
    ///
    /// + Note: This method will not be called for cancelled requests.
    ///
    /// - parameter seqNo: Sequence number of the corresponding request.
    /// - parameter content: The response's content (in case of success).
    /// - parameter error: The error (in case of failure).
    ///
    func handleResponse(seqNo: Int, content: [String: Any]?, error: Error?)
    
    /// Handle a request cancellation.
    ///
    /// - parameter seqNo: Sequence number of the cancelled request.
    ///
    func requestWasCancelled(seqNo: Int)
}


/// Manages a sequence of requests.
/// A `Sequencer` keeps track of the order in which requests have been issued, and cancels obsolete requests whenever a
/// response to a more recent request is received. This ensures that responses are always received in the right order,
/// or discarded.
///
/// + Note: Requests can be any kind of `Operation`.
///
internal class Sequencer: NSObject {
    
    // MARK: Properties
    
    /// Delegate to this sequencer.
    public weak var delegate: SequencerDelegate?
    
    /// Sequence number for the next request.
    ///
    /// + Note: Shared across all instances for ease of observation.
    ///
    /// Sequence number for the next request.
    private static var nextSeqNo: Int = 0
    
    /// Queue used to serialize accesses to `nextSeqNo`.
    private static let lockQueue = DispatchQueue(label: "Sequencer.lock")
    
    /// Sequence number of the last request.
    public private(set) var lastRequestedSeqNo: Int?
    
    /// Sequence number of the last received response.
    public private(set) var lastReceivedSeqNo: Int?
    
    /// All currently ongoing requests.
    private var pendingRequests: [Int: Operation] = [:]
    
    /// Maximum number of pending requests allowed.
    /// If many requests are made in a short time, this will keep only the N most recent and cancel the older ones.
    /// This helps to avoid filling up the request queue when the network is slow.
    ///
    public var maxPendingRequests: Int = 3
    
    // MARK: - Initialization, termination
    
    internal init(delegate: SequencerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    // MARK: - Sequencing logic

    /// Launch next request.
    internal func next() {
        guard let delegate = delegate else { return }

        // Increase sequence number.
        let currentSeqNo: Int = Sequencer.lockQueue.sync {
            Sequencer.nextSeqNo += 1
            return Sequencer.nextSeqNo
        }
        lastRequestedSeqNo = currentSeqNo
        
        // Cancel obsolete requests.
        let obsoleteRequests = pendingRequests.filter({ $0.0 <= currentSeqNo - maxPendingRequests })
        for (seqNo, _) in obsoleteRequests {
            cancelRequest(seqNo: seqNo)
        }

        // Launch request.
        var operation: Operation!
        let completionHandler: CompletionHandler = {
            [weak self]
            (content, error) in
            // NOTE: We do not control the lifetime of the sequencer. => Fail gracefully if already released.
            guard let this = self else { return }

            // Cancel all previous requests (as this one is deemed more recent).
            let previousRequests = this.pendingRequests.filter({ $0.0 < currentSeqNo })
            for (seqNo, _) in previousRequests {
                this.cancelRequest(seqNo: seqNo)
            }

            // Remove the current request.
            this.pendingRequests.removeValue(forKey: currentSeqNo)
            
            // Obsolete requests should not happen since they have been cancelled by more recent requests (see above).
            // WARNING: Only works if the current queue is serial!
            assert(this.lastReceivedSeqNo == nil || this.lastReceivedSeqNo! < currentSeqNo)

            // Update last received response.
            this.lastReceivedSeqNo = currentSeqNo
            
            // Call the response handler.
            this.delegate?.handleResponse(seqNo: currentSeqNo, content: content, error: error)
        }
        operation = delegate.startRequest(seqNo: currentSeqNo, completionHandler: completionHandler)
        self.pendingRequests[currentSeqNo] = operation
    }
    
    // MARK: - Manage requests
    
    /// Indicates whether there are any pending requests.
    public var hasPendingRequests: Bool {
        return !pendingRequests.isEmpty
    }
    
    /// Cancel all pending requests.
    public func cancelPendingRequests() {
        for seqNo in pendingRequests.keys {
            cancelRequest(seqNo: seqNo)
        }
        assert(pendingRequests.isEmpty)
    }
    
    /// Cancel a specific request.
    ///
    /// - parameter seqNo: The request's sequence number.
    ///
    public func cancelRequest(seqNo: Int) {
        if let request = pendingRequests[seqNo] {
            request.cancel()
            delegate?.requestWasCancelled(seqNo: seqNo)
            pendingRequests.removeValue(forKey: seqNo)
        }
    }
}
