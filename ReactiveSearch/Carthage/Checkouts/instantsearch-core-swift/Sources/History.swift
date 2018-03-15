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
import Foundation


/// Records a history of searches.
///
@objc public class HistoryRecorder: NSObject {
    // MARK: Properties

    /// The searcher being observed.
    @objc public let searcher: Searcher
    
    /// The history being fed.
    @objc public let history: History
    
    /// Delay by which to debounce searches before recording them.
    /// This is to avoid making too many requests to the history, especially when it is remote.
    @objc public var delay: TimeInterval = 1.0 {
        didSet {
            debouncer.delay = self.delay
        }
    }

    /// Debouncer used to avoid updating the history after each keystroke.
    private let debouncer: Debouncer

    // MARK: Initialization
    
    /// Create a new recorder observing a searcher and feeding a history.
    ///
    /// - parameter searcher: The searcher to observer.
    /// - parameter history: The history to feed.
    ///
    @objc public init(searcher: Searcher, history: History) {
        self.searcher = searcher
        self.history = history
        self.debouncer = Debouncer(delay: self.delay)
        super.init()
        observeSearchNotifications()
    }
  
    private func observeSearchNotifications() {
      NotificationCenter.default.addObserver(forName: Searcher.SearchNotification, object: searcher, queue: nil) { (notification) in
        guard let params = notification.userInfo?[Searcher.userInfoParamsKey] as? SearchParameters else { return }
        let searchIsFinal = notification.userInfo?[Searcher.userInfoIsFinalKey] as? Bool ?? false
        if searchIsFinal { // final searches go straight into the history
          self.history.add(params)
        } else { // as-you-type searches are debounced
          self.debouncer.call {
            self.history.add(params)
          }
        }
      }
    }
}

/// Manages a history of previous searches.
///
@objc public protocol History {
    /// Add a new query to the history.
    ///
    /// - parameter params: The search parameters of the query to add.
    ///
    @objc func add(_ params: SearchParameters)
    
    /// Search the history.
    ///
    /// - parameter query: The searched query.
    /// - parameter options: Search options.
    /// - returns: A list of matching queries in the history.
    ///
    @objc func search(query: SearchParameters, options: HistorySearchOptions) -> [HistoryHit]
}

/// Options when searching a `History`.
///
@objc public class HistorySearchOptions: NSObject {
    /// Tag prepended to highlights.
    @objc public var highlightPreTag: String = "<em>"
    
    /// Tag appended to highlights.
    @objc public var highlightPostTag: String = "</em>"

    /// Maximum number of hits to return.
    @objc public var maxHits: Int = 10
}

/// A hit from the history.
///
@objc public class HistoryHit: NSObject {
    // MARK: Properties

    /// Search parameters corresponding to this hit.
    @objc public let params: SearchParameters
    
    /// An highlighted text representation of the hit.
    /// Usually contains the `params.query` parameter, highlighted to show which part matched the searched string.
    @objc public let highlightedText: String

    // MARK: Initialization

    /// Create a new hit.
    @objc public init(params: SearchParameters, highlightedText: String) {
        self.params = params
        self.highlightedText = highlightedText
    }
}

/// A history that sits on the local device.
///
/// By default, the history sits purely in memory. If `filePath` is set, it is also persisted on disk.
///
@objc public class LocalHistory: NSObject, History {
    // MARK: Properties
    
    /// The in-memory cache of the history's content.
    private var queries: NSMutableOrderedSet = NSMutableOrderedSet()

    /// The history's content, ordered by recency (read-only).
    @objc public var contents: [String] {
        return queries.array as! [String]
    }
    
    /// Maximum number of entries allowed in this history. Default = 10.
    @objc public var maxCount: Int = 10 {
        didSet {
            purge()
        }
    }
    
    /// Whether each query added automatically trigges a save. Default = `true`.
    ///
    /// + Note: The save will be performed asynchronously for better performance.
    ///
    @objc public var autosave: Bool = true
    
    /// File path to the history on disk.
    /// If `nil` (default), the history will sit purely in memory.
    @objc public var filePath: String?
    
    // MARK: Initialization
    
    /// Create a new, empty history that sits purely in memory.
    public override init() {
    }
    
    /// Create a new history that is persisted on disk.
    ///
    /// - parameter filePath: Path to the history file on disk.
    ///
    public init(filePath: String) {
        self.filePath = filePath
        super.init()
        self.load()
    }
    
    // MARK: History management
    
    /// Search the history.
    ///
    /// + Complexity: O(n): grows linearly with the size of the history.
    ///   This should remain acceptable if the history is small (a few tens of entries).
    ///
    /// - parameter query: The searched query. By convention, an empty search matches the entire history
    ///                    (up to `options.maxHits`).
    /// - parameter options: Search options.
    /// - returns: A list of matching hits in the history. They are ordered by recency (most recent first).
    ///
    @objc public func search(query: SearchParameters, options: HistorySearchOptions = HistorySearchOptions()) -> [HistoryHit] {
        var hits: [HistoryHit] = []
        let text = query.query ?? ""
        let searchedText = normalize(text)
        // Only search for the text at the beginning of a word.
        let searchedPattern = "\\b" + searchedText

        for query in queries {
            // Stop when `maxHits` is reached.
            if hits.count >= options.maxHits {
                break
            }
            let queryString = query as! String
            
            var highlightedText: String
            if searchedText.isEmpty { // empty search: everything matches, no highlighting necessary
                highlightedText = queryString
            } else { // non-empty search
                if let foundRange = queryString.range(of: searchedPattern, options: .regularExpression) {
                    // NOTE: We don't handle multiple occurrences as they are assumed to be rare.
                    // Also, highlighting would be weird in a suggestion context.
                  highlightedText = String(queryString[..<foundRange.lowerBound]) + options.highlightPreTag + String(queryString[foundRange]) + options.highlightPostTag + String(queryString[foundRange.upperBound...])
                } else {
                    continue
                }
            }
            // Add hit.
            let params = SearchParameters()
            params.query = queryString
            hits.append(HistoryHit(params: params, highlightedText: highlightedText))
        }
        return hits
    }
    
    /// Add a new query to the history.
    ///
    /// Deduplication will occur:
    ///
    /// 1. If the new query is a prefix of an existing query not stopping at a word boundary, it is discarded.
    ///   For example, if the history contains "star wars", "star war" will not be added, but "star" will be.
    /// 2. If an existing query is a prefix of the new query not stopping at a word boundary, the existing query is
    ///   replaced by the new one. For example, if the history contains "star war", "star wars" will replace it,
    ///   but "star war fan" will add a new entry.
    /// 3. If the same query already exists, it is updated.
    ///
    /// When the new query does make it into the history, it automatically becomes the most recent entry, possibly
    /// evicting the less recent entry (LRU principle).
    ///
    /// - parameter params: The search parameters of the query to add.
    ///
    @objc public func add(_ params: SearchParameters) {
        guard var newText = params.query else { return }
        
        // Normalize query string.
        newText = normalize(newText)
        if newText.isEmpty {
            return
        }
        
        // Add or update the query.
        let index = queries.index(of: newText)
        if index != NSNotFound {
            // If the text is found exactly, just move it to the front of the queue (LRU).
            queries.moveObjects(at: IndexSet(integer: index), to: 0)
        } else {
            // Check that the new text is not redundant with existing texts:
            // - If the new text is a prefix of an existing text, reject it, unless it ends on a word boundary.
            // - If an existing text is a prefix of the new text, replace it, unless it ends on a word boundary.
            var redundant = false
            if let newTextPrefixPattern = try? NSRegularExpression(pattern: "^" + newText + "(?!\\b)", options: .useUnicodeWordBoundaries) {
                for i in 0 ..< queries.count {
                    let oldText = queries[i] as! String
                    if newTextPrefixPattern.firstMatch(in: oldText, range: NSMakeRange(0, (oldText as NSString).length)) != nil {
                        // New text is a prefix of the old text, not ending on a word boundary.
                        redundant = true
                        break
                    }
                    guard let oldTextPrefixPattern = try? NSRegularExpression(pattern: "^" + oldText + "(?!\\b)", options: .useUnicodeWordBoundaries) else { continue }
                    if oldTextPrefixPattern.firstMatch(in: newText, range: NSMakeRange(0, (newText as NSString).length)) != nil {
                        // Old text is a prefix of the new text, not ending on a word boundary.
                        redundant = true
                        // Update the existing entry...
                        queries[i] = newText
                        // ... and move it first.
                        queries.moveObjects(at: IndexSet(integer: i), to: 0)
                        break
                    }
                }
            }
            if !redundant {
                queries.insert(newText, at: 0)
            }
        }

        // Clean up.
        purge()
        saveIfNeeded()
    }
    
    /// Remove all entries from the history.
    ///
    @objc public func clear() {
        queries.removeAllObjects()
        saveIfNeeded()
    }
    
    // MARK: Persistence
    
    private func purge() {
        if queries.count > maxCount {
            queries.removeObjects(at: IndexSet(integersIn: Range(uncheckedBounds: (maxCount, queries.count))))
        }
    }
    
    private func saveIfNeeded() {
        if autosave && filePath != nil {
            saveAsync()
        }
    }

    /// Save the history to disk (synchronously).
    ///
    @objc public func save() {
        guard let filePath = filePath else { return }
        let values = queries.array
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
        } catch _ {
            // Ignore
        }
    }

    /// Save the history to disk (asynchronously).
    ///
    /// + Note: No completion handler is provided, as the history is not considered to be mission-critical.
    ///
    @objc public func saveAsync() {
        guard let filePath = filePath else { return }
        let values = queries.array
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
                try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            } catch _ {
                // Ignore
            }
        }
    }

    /// Load the history from disk (synchronously).
    ///
    @objc public func load() {
        guard let filePath = filePath else { return }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            if let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String] {
                queries = NSMutableOrderedSet(array: values)
            }
        } catch _ {
            // Ignore
        }
    }
    
    // MARK: Utils
    
    private let whitespaceRegex: NSRegularExpression = {
        return (try? NSRegularExpression(pattern: "\\s+"))!
    }()
    
    /// Normalize a string for storage in the history.
    ///
    private func normalize(_ text: String) -> String {
        return whitespaceRegex
            // Replace each sequence of whitespace by a single space.
            .stringByReplacingMatches(in: text, options: [], range: NSMakeRange(0, (text as NSString).length), withTemplate: " ")
            // Trim leading and trailing whitespace.
            .trimmingCharacters(in: .whitespaces)
            // Convert to lower case.
            .lowercased()
    }
}
