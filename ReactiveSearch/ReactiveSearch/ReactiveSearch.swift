//
//  ReactiveSearch.swift
//  ReactiveSearch
//
//  Created by Robert Mogos on 02/03/2018.
//  Copyright © 2018 Robert Mogos. All rights reserved.
//

import Foundation
import AlgoliaSearch
import InstantSearchCore
import RxSwift

@objcMembers public class ReactiveSearch: NSObject {
  public static let shared = ReactiveSearch()
  //@objc public dynamic var results: SearchResults = SearchResults()
  
  private var searchResultsInput: Input<SearchResults> = Input(SearchResults())
  public var searchResults: I<SearchResults> {
    return searchResultsInput.i
  }
  private var _searchResults: SearchResults = SearchResults() {
    didSet {
      searchResults.write(_searchResults)
    }
  }
  
  public var searcher: Searcher!
  
  @objc public convenience init(appID: String, apiKey: String, index: String) {
    self.init()
    self.configure(appID: appID, apiKey: apiKey, index: index)
  }
  
  @objc public func configure(appID: String, apiKey: String, index: String) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: index)
    let searcher = Searcher(index: index)
    self.searcher = searcher
    self.searcher.delegate = self
  }
  
  public func search(with searchText: String) {
    searcher.params.query = searchText
    search()
  }
  
  public func search() {
    self.searcher.search()
  }
  
  public func loadMore() {
    searcher.loadMore()
  }
}

extension ReactiveSearch: SearcherDelegate {
  public func searcher(_ searcher: Searcher, didReceive results: SearchResults?, error: Error?, userInfo: [String: Any]) {
    if let results = results {
      _searchResults = results
    }
  }
}

extension ReactiveSearch {
//  public func observe(_ indexVariant: String, changeHandler: @escaping (Searcher, NSKeyValueObservedChange<SearchResults?>) -> Void) -> NSKeyValueObservation {
//
//    let observer: NSKeyValueObservation = searcher.observe(\.results, options: [.new, .old, .initial], changeHandler: changeHandler)
//    return observer
//  }
  
  
}
