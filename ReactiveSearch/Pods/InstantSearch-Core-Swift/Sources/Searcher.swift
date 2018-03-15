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


// ------------------------------------------------------------------------
// IMPLEMENTATION NOTES
// ------------------------------------------------------------------------
// # Sequencing logic
//
// An important part of the `Searcher` is to manage the proper sequencing
// of search requests and responses.
//
// Conceptually, a search session can be seen as a sequence of *queries*,
// each query resulting in one or more *requests* to the API (one per page).
// Each request is assigned an auto-incremented sequence number.
//
// Example:
//
// ```
// Queries:    A --> B --> C --> D
//             |     |     |     |
// Requests:   1     2     4     6
//             …     |     |
//            (X)    3     5
// ```
//
// Now, there are important rules to guarantee a consistent behavior:
//
// 1. A `loadMore()` request for a query will be ignored if a more recent
//    query has already been requested.
//
//    For example, in the diagram above: request X (page 2 of query A) will
//    be ignored if request 2 (page 1 of query B) has already been sent.
//
// 2. Results for a request will be ignored if results have already been
//    received for a more recent request.
//
//    For example, in the diagram above: results for request 3 will be
//    ignored if results have already been received for request 4.
//
// ------------------------------------------------------------------------


/// Delegate to a `Searcher`.
///
@objc public protocol SearcherDelegate {
    /// Called when a response to a request has been received by a searcher.
    /// Can be a success or an error, depending on which of `results` or `error` is non-nil.
    ///
    /// - parameter searcher: The `Searcher` instance that received a response.
    /// - parameter results: The request's results, or `nil` in case of error.
    /// - parameter error: The error that was encountered, or `nil` in case of success.
    /// - parameter userInfo: Extra information such as the search parameters of the request corresponding to the present response.
    ///
    @objc(searcher:didReceiveResults:error:userInfo:)
    func searcher(_ searcher: Searcher, didReceive results: SearchResults?, error: Error?, userInfo: [String: Any])
}


/// Manages search on an Algolia index.
///
/// The purpose of this class is to maintain a state between searches and handle pagination.
///
/// ### Handling results
///
/// There are three ways to handle responses to search requests issued by a `Searcher`. From the highest level to the
/// lowest level, they are:
///
/// 1. Register a **result handler** block. It will be called each time a response is received, providing the
///    results (in case of success), the error (in case of failure) and extra information such as the search parameters
///    of the request corresponding to the present response. You may register as many result handlers as necessary.
///
/// 2. Register a **delegate**. It provides one additional information, which is the `Searcher` instance that received the
///    response. You may register at most one delegate.
///
/// 3. Listen for **notifications** issued by this searcher (using `NotificationCenter`). Notifications give you
///    extra information, such as whether requests are cancelled by the searcher.
///
@objc public class Searcher: NSObject, SequencerDelegate {
    
    // MARK: Types
    
    /// Handler for search results.
    ///
    /// - parameter results: The results (in case of success).
    /// - parameter error: The error (in case of failure).
    /// - parameter userInfo: Extra information such as the search parameters.
    ///

    public typealias ResultHandler = @convention(block) (_ results: SearchResults?, _ error: Error?, _ userInfo: [String: Any]) -> Void
    /// Pluggable state representation.
    private struct State: CustomStringConvertible {
        /// Filters.
        var params: SearchParameters = SearchParameters()
        
        /// List of facets to be treated as disjunctive facets. Defaults to the empty list.
        var disjunctiveFacets: [String] { return Array(params.disjunctiveFacets) }
        
        /// Search metadata.
        var userInfo: [String: Any] = [:]

        /// Convenience accessor to the requested page.
        var page: UInt {
            get { return params.page ?? 0 }
            set { params.page = newValue }
        }
        
        /// Construct a default state.
        init() {
        }

        // WARNING: Although `State` is a value type, `Query` is not (because of Objective-C bridgeability).
        // Consequently, the memberwise assignment of `State` leads to unintended state sharing.
        //
        // TODO: I found no way to customize the assignment of a struct in Swift (something like C++'s assignment
        // operator or copy constructor). So I resort to explicitly constructing copies so far.

        /// Copy a state.
        init(copy: State) {
            // WARNING: `SearchParameters` is not a value type (because of Objective-C bridgeability), so let's make
            // sure to copy it.
            self.params = SearchParameters(from: copy.params)
            self.userInfo = copy.userInfo
        }
        
        var description: String {
            return "State{params=\(params), disjunctiveFacets=\(disjunctiveFacets)}"
        }
    }
    
    // MARK: Properties

    /// The index used by this searcher.
    ///
    /// + Note: Modifying the index doesn't alter the searcher's state. In particular, pending requests are left
    ///   running. Depending on your use case, you might want to call `reset()` after changing the index.
    ///
    @objc public var index: Searchable
    
    /// The delegate to this searcher.
    ///
    /// + Warning: The delegate is not retained. It is the caller's responsibility to ensure that it remains valid for
    ///            the lifetime of the searcher.
    ///
    @objc public var delegate: SearcherDelegate?
    
    /// Strategy used by this searcher.
    /// If `nil`, all searches are fired immediately. Otherwise, the strategy decides if and when searches are
    ///
    /// + Note: The searcher only keeps a weak reference to its strategy. It is the caller's responsibility to
    ///         make sure the strategy's lifetime exceeds that of the searcher.
    ///
    @objc public weak var strategy: RequestStrategy?
    
    /// Request sequencer used to guarantee the order of responses.
    private var sequencer: Sequencer!
    
    /// User callbacks for handling results.
    /// There should be at least one, but multiple handlers may be registered if necessary.
    ///
    private var resultHandlers: [ResultHandler] = []
    
    /// Search parameters for the next query.
    ///
    @objc public var params: SearchParameters { return nextState.params }

    // State management
    // ----------------
    
    /// The state that will be used for the next search.
    /// It can be modified at will. It is not taken into account until the `search()` method is called; then it is
    /// copied and transferred to `requestedState`.
    private var nextState: State = State()

    /// The states corresponding to each pending request.
    private var states: [Int: State] = [:]
    
    /// The state corresponding to the last issued request.
    ///
    /// + Warning: Only valid after the first call to `search()`.
    ///
    private var requestedState: State!

    /// The state corresponding to the last received results.
    ///
    /// + Warning: Only valid after the first call to the result handler.
    ///
    private var receivedState: State!
    
    /// The last received results.
    @objc public private(set) var results: SearchResults?
    
    /// The hits for all pages requested of the latest query.
    @objc public private(set) var hits: [[String: Any]] = []
    
    // Name of the index that the Searcher targets.
    public var indexName: String = ""
    
    /// variant to differentiate between searchers that target the same index.
    public var variant: String = ""
    
    /// Maximum number of pending requests allowed.
    /// If many requests are made in a short time, this will keep only the N most recent and cancel the older ones.
    /// This helps to avoid filling up the request queue when the network is slow.
    ///
    @objc public var maxPendingRequests: Int {
        get { return sequencer.maxPendingRequests }
        set { sequencer.maxPendingRequests = newValue }
    }
    
    // MARK: - Initialization, termination
    
    /// Create a new searcher targeting the specified index.
    ///
    /// - parameter index: The index to target when searching.
    ///
    @objc public init(index: Searchable) {
        self.index = index
        super.init()
        self.sequencer = Sequencer(delegate: self)
        Searcher._updateClientUserAgents
    }
    
    /// Create a new searcher targeting the specified index and register a result handler with it.
    ///
    /// - parameter index: The index to target when searching.
    /// - parameter resultHandler: The result handler to register.
    ///
    @objc public convenience init(index: Searchable, resultHandler: @escaping ResultHandler) {
        self.init(index: index)
        self.resultHandlers = [resultHandler]
    }
    
    /// Add the library's version to the client's user agents, if not already present.
    private static let _updateClientUserAgents: Void = {
        let bundleInfo = Bundle(for: Searcher.self).infoDictionary!
        let name = bundleInfo["CFBundleName"] as! String
        let version = bundleInfo["CFBundleShortVersionString"] as! String
        let libraryVersion = LibraryVersion(name: name, version: version)
        Client.addUserAgent(libraryVersion)
    }()
  
    /// Register a result handler with this searcher.
    ///
    /// + Note: Because of the way closures are handled in Swift, the handler cannot be removed.
    ///
    @objc public func addResultHandler(_ resultHandler: @escaping ResultHandler) {
        self.resultHandlers.append(resultHandler)
    }
    
    /// Reset the search state.
    /// This resets the `query`, `disjunctiveFacets` and `filters` properties. It also cancels any pending request.
    ///
    /// + Note: It does *not* remove registered result handlers.
    ///
    @objc public func reset() {
        params.clear()
        cancelPendingRequests()
        results = nil
        hits = []
    }
    
    // MARK: - Search
    
    /// Search using the current settings, with empty search metadata.
    ///
    @objc public func search() {
        search(userInfo: [:])
    }
    
    /// Search using the current settings.
    /// This uses the current value for `query`, `disjunctiveFacets` and `refinements`.
    ///
    /// If `strategy` is not `nil`, the strategy delegate will decide if, when and how the search will be performed.
    ///
    /// - parameter userInfo: Search metadata.
    ///
    @objc public func search(userInfo: [String: Any]) {
        if let strategy = strategy {
            strategy.performSearch(from: self, userInfo: userInfo, with: self._search)
        } else {
            _search(userInfo: userInfo)
        }
    }

    /// Effectively trigger a search.
    ///
    /// - parameter userInfo: Search metadata.
    ///
    private func _search(userInfo: [String: Any]) {
        // Take the next state as is...
        requestedState = State(copy: nextState)
        // ... and override the metadata entirely.
        requestedState.userInfo = userInfo
        // Launch the search.
        sequencer.next()
    }
    
    /// Load more content, if possible.
    @objc public func loadMore() {
        if !canLoadMore() {
            return
        }
        if !hasMore() {
            return
        }
        // Derive a new state from the received state.
        let nextPage = receivedState!.page + 1
        // Don't load more if already loading.
        if nextPage <= requestedState.page {
            return
        }
        // OK, everything's fine; let's go!
        // Just alter the previous state by overriding the page...
        requestedState.page = nextPage
        // ... and the `isLoadingMore` flags.
        requestedState.userInfo[Searcher.userInfoIsLoadingMoreKey] = true
        // Launch the search.
        sequencer.next()
    }
    
    /// Test whether the current state allows loading more results.
    /// Loading more requires that we have already received results (obviously) and also that another more recent
    /// request is not pending.
    ///
    /// + Note: It does indicate whether they are actually more results to load. For this, see `hasMore()`.
    ///
    /// - returns: true if the current state allows loading more results, false otherwise.
    ///
    private func canLoadMore() -> Bool {
        // Cannot load more when no results have been received.
        guard let receivedState = receivedState, let _ = results else {
            return false
        }
        // Must not load more if the results are outdated with respect to the currently on-going search.
        if requestedState.params != receivedState.params {
            return false
        }
        return true
    }
    
    /// Test whether the current results have more pages to load.
    ///
    /// - returns: true if more pages are available, false otherwise or if no results have been received yet.
    ///
    private func hasMore() -> Bool {
        // If no results have been received yet, there are obviously no additional pages.
        guard let receivedState = receivedState, let results = results else { return false }
        return Int(receivedState.page) + 1 < results.nbPages
    }
    
    // MARK: - SequencerDelegate
    
    func startRequest(seqNo: Int, completionHandler: @escaping CompletionHandler) -> Operation {
        // Freeze state.
        var state = State(copy: requestedState)
        
        // Build query.
        let params = SearchParameters(from: state.params)
        params.page = UInt(state.page)
        params.facetFilters = [] // NOTE: will be overridden below

        var operation: Operation
        if state.disjunctiveFacets.isEmpty {
            // All facets are conjunctive; build regular filters combining numeric and facet refinements.
            // NOTE: Not strictly necessary since `Index.search(...)` calls `Query.build()`, but let's not rely on that.
            params.update()
            operation = index.search(params, requestOptions: nil, completionHandler: completionHandler)
        } else {
            // Facet filters are built directly by the disjunctive faceting search helper method.
            params.updateFromNumerics() // this is really necessary (in contrast to the above)
            let refinements = params.buildFacetRefinements()
            operation = index.searchDisjunctiveFaceting(params, disjunctiveFacets: state.disjunctiveFacets, refinements: refinements, requestOptions: nil, completionHandler: completionHandler)
        }
        
        // Notify observers.
        state.userInfo[Searcher.userInfoParamsKey] = params
        state.userInfo[Searcher.userInfoSeqNoKey] = seqNo
        // Do it asynchronously, so that the sequencer has added the request to the list of pending requests.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Searcher.SearchNotification, object: self, userInfo: state.userInfo)
        }

        // Memorize state.
        states[seqNo] = state
        
        return operation
    }
    
    func handleResponse(seqNo: Int, content: [String: Any]?, error: Error?) {
        // Memorize state and clean up map.
        receivedState = states[seqNo]
        states[seqNo] = nil

        var finalError = error
        do {
            if let content = content {
                let searchResults = try SearchResults(content: content, disjunctiveFacets: receivedState!.disjunctiveFacets)
                self.results = searchResults
                
                // Update hits.
                let isLoadingMore = receivedState.userInfo[Searcher.userInfoIsLoadingMoreKey] as? Bool ?? false
                if isLoadingMore {
                    self.hits.append(contentsOf: searchResults.hits)
                } else {
                    self.hits = searchResults.hits
                }

                callResultHandlers(results: self.results, error: nil, userInfo: receivedState.userInfo)
                return
            }
        } catch let e {
            finalError = e
        }
        callResultHandlers(results: nil, error: finalError, userInfo: receivedState.userInfo)
    }
    
    func requestWasCancelled(seqNo: Int) {
        NotificationCenter.default.post(name: Searcher.CancelNotification, object: self, userInfo: [
            Searcher.userInfoSeqNoKey: seqNo
        ])
        // Clean up state.
        states[seqNo] = nil
    }

    /// Call the various types of result handlers.
    /// This dispatches the same information to the delegate, the block handlers and via notifications.
    ///
    /// - parameter results: The search results (in case of success).
    /// - parameter error: The error (in case of failure).
    /// - parameter userInfo: Search metadata.
    ///
    private func callResultHandlers(results: SearchResults?, error: Error?, userInfo: [String: Any]) {
        // Notify delegate.
        delegate?.searcher(self, didReceive: results, error: error, userInfo: userInfo)

        // Notify result handlers.
        for resultHandler in resultHandlers {
            resultHandler(results, error, userInfo)
        }

        // Notify observers.
        var userInfo = userInfo // need to add results or error
        if let results = results {
            userInfo[Searcher.resultNotificationResultsKey] = results
            NotificationCenter.default.post(name: Searcher.ResultNotification, object: self, userInfo: userInfo)
        }
        else if let error = error {
            userInfo[Searcher.errorNotificationErrorKey] = error
            NotificationCenter.default.post(name: Searcher.ErrorNotification, object: self, userInfo: userInfo)
        }
    }
    
    // MARK: - Search for facet values
    
    /// Search for values of a given facet.
    ///
    /// This is a convenience shortcut for Algolia Search's `Index.searchForFacetValues(...)` method that will
    /// automatically use the current search `params` as the refining query, also taking into account the
    /// conjunctive/disjunctive status of the targeted facet (i.e. refinements for the targeted facet will be discarded
    /// when the facet is disjunctive).
    ///
    /// Unlike a regular `search()`:
    ///
    /// - The searched text has to be passed as an argument to the method, as it differs in purpose from `params.query`.
    /// - Result handlers or the delegate are not called; instead, the provided completion handler is called.
    ///   Notifications are not issued either.
    ///
    /// - parameter facetName: Name of the facet to search. It must have been declared in the index's
    ///       `attributesForFaceting` setting with the `searchable()` modifier.
    /// - parameter text: Text to search for in the facet's values.
    /// - parameter completionHandler: Completion handler to be notified of the request's outcome.
    /// - returns: A cancellable operation.
    ///
    @objc @discardableResult
    public func searchForFacetValues(of facetName: String, matching text: String, completionHandler: @escaping CompletionHandler) -> Operation {
        let facetSearchParams = SearchParameters(from: self.params)
        // If the searched facet is disjunctive, clear any refinements that it may have.
        if facetSearchParams.isDisjunctiveFacet(name: facetName) {
            facetSearchParams.clearFacetRefinements(name: facetName)
        }
        return index.searchForFacetValues(of: facetName, matching: text, query: facetSearchParams, requestOptions: nil, completionHandler: completionHandler)
    }
    
    // MARK: - Manage requests
    
    /// Indicates whether there are any pending requests.
    @objc public var hasPendingRequests: Bool {
        return sequencer.hasPendingRequests
    }

    /// Cancel all pending requests.
    @objc public func cancelPendingRequests() {
        sequencer.cancelPendingRequests()
    }
    
    /// Cancel a specific request.
    ///
    /// - parameter seqNo: The request's sequence number.
    ///
    @objc public func cancelRequest(seqNo: Int) {
        sequencer.cancelRequest(seqNo: seqNo)
    }
    
    // MARK: - Notifications
    
    /// Notification sent when a request is sent through the API Client.
    /// This can be either on `search()` or `loadMore()`.
    ///
    @objc public static let SearchNotification = Notification.Name("search")
    
    /// Notification sent when a successful response is received from the API Client.
    @objc public static let ResultNotification = Notification.Name("result")
    
    /// Key containing the search results in a `ResultNotification`.
    /// Type: `SearchResults`.
    ///
    @objc public static let resultNotificationResultsKey: String = "results"
    
    /// Notification sent when a request is cancelled by the searcher.
    /// The result handler will not be called for cancelled requests, nor will any `ResultNotification` or
    /// `ErrorNotification` be posted, so this is your only chance of being informed of cancelled requests.
    ///
    @objc public static let CancelNotification = Notification.Name("cancel")

    /// Notification sent when an erroneous response is received from the API Client.
    @objc public static let ErrorNotification = Notification.Name("error")
    
    /// Key containing the error in an `ErrorNotification`.
    /// Type: `Error`.
    ///
    @objc public static let errorNotificationErrorKey: String = "error"
    
    /// Notification sent when a numeric or facet refinement has been added, removed or updated.
    @objc public static let RefinementChangeNotification = Notification.Name("refinementChange")
    
    /// Key containing all the numeric refinements in a `RefinementChangeNotification`.
    @objc public static let userInfoNumericRefinementChangeKey = "numericRefinementChange"
    
    /// Key containing all the facet refinements in a `RefinementChangeNotification`.
    @objc public static let userInfoFacetRefinementChangeKey = "facetRefinementChange"
    
    /// Key containing the request sequence number in a `SearchNotification`, `ResultNotification`, `ErrorNotification`
    /// or `CancelNotification`. The sequence number uniquely identifies the request across all `Searcher` instances.
    /// Type: `Int`.
    ///
    @objc public static let userInfoSeqNoKey: String = "seqNo"
    
    /// Key containing the search query in a `SearchNotification`, `ResultNotification` or `ErrorNotification`.
    /// Type: `SearchParameters`.
    ///
    @objc public static let userInfoParamsKey: String = "params"
    
    /// Key containing the isLoadingMore query in a `SearchNotification`, `ResultNotification` or `ErrorNotification`.
    /// Type: `Bool`.
    ///
    @objc public static let userInfoIsLoadingMoreKey: String = "isLoadingMore"
    
    /// User info key indicating whether the search is final (as opposed to an as-you-type search).
    /// Typically, keystrokes in a search bar are as-you-type, whereas a tap on the "Search" button is final.
    /// Type: `Bool`.
    ///
    @objc public static let userInfoIsFinalKey: String = "isFinal"
}
