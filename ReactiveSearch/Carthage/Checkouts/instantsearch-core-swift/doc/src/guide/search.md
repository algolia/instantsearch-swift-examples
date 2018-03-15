---
title: Search
layout: guide.mustache
---

# Search

## Setup

First create a `Client` and an `Index` as you would do with the bare API Client:

```swift
let client = Client(appID: "YOUR_APP_ID", apiKey: "YOUR_API_KEY")
let index = client.index(withName: "index_name")
```

Then create a `Searcher` targeting the index; you typically specify a result handler during creation (although you can register more later):

```swift
let searcher = Searcher(index: index, resultHandler: self.handleResults)
```

A closure is accepted as well:

```swift
let searcher = Searcher(index: index, resultHandler: { (results: SearchResults?, error: Error?, userInfo: [String: Any]) in
    // Your code goes here.
})
```

## Searching

The searcher will only launch a request when you call its `search()` method. Before you search, of course, you will want to modify the **search parameters** via the `params` property (a `SearchParameters` instance):

```swift
searcher.params.query = "hotel"
searcher.params.aroundLatLngViaIP = true
searcher.search()
```

### Metadata

The `search(...)` method takes an optional `userInfo` argument, which contains search **metadata**. This metadata will be propagated (and possibly enriched or altered) throughout the lifetime of the request, up to the observers.

The contents of the metadata can be anything you want. Some **well-known keys** are provided by the `Searcher` class: see the `*Key` constants.

## Handling results

The searcher will call your result handler after each request, when the response is received, *unless the request has been cancelled* (e.g. because newer results have already been received). Typically, your result handler will check for errors, store the hits in some data structure, then reload your UI:

```swift
func handleResults(results: SearchResults?, error: Error?, userInfo: [String: Any]) {
    guard let results = results else { return }
    self.hits = results.hits
    self.tableView.reloadData()
}
```

The `SearchResults` class is a wrapper around the JSON response received from the API. You can always access the underlying JSON directly through the `content` property. However, the fields you will most likely are also exposed via typed properties, such as `hits` or `nbHits`. You also get convenience accessors for:

- facet values (`facets(name:)`) and statistics (`facetStats(name:)`);
- highlights (`highlightResult(at:path:)`) and snippet results (`snippetResult(at:path:)`)
- ranking information (`rankingInfo(at:)`)

Please note that not every piece of information may be present in the response; it depends on your request.


## Continuous scrolling

The searcher facilitates the implementation of continuous scrolling through its `loadMore()` method. Fetching the next page of results is as easy as calling this method.

Note that if you use continuous scrolling, then you must take care to *append* hits to your internal data structure instead of erasing them. Using the `page` property is usually sufficient:

```swift
if results.page == 0 {
    self.hits = results.hits
} else {
    self.hits.append(contentsOf: results.hits)
}
```

When should you call `loadMore()`? Whenever your UI detects the need to fetch more data. Note that, in order to provide a smooth scrolling experience, it is wiser to pre-fetch data before it is required. A good indicator is when your table view or collection view data source is called for cells near the end of the currently available data. Alternatively, you can use the `UICollectionView` data source pre-fetching introduced in iOS 10.

The `loadMore()` method is guarded against concurrent or inconsistent calls. If you try to call it while another request has already been issued, it will ignore the call.


## Filtering

### Facets

The search parameters maintain a list of refined values for every facet, called **facet refinements**. A facet refinement is the combination of an attribute name and a value. Optionally, the refinement can be negated (i.e. treated as exclusive rather than inclusive).

To edit the refinements, use the facet refinement handling methods, like `addFacetRefinement(name:value:)`, `removeFacetRefinement(name:value:)` and `toggleFacetRefinement(name:value:)`.

A given facet can be treated as either **conjunctive** (the default---refinements combined with an `AND` operator) or **disjunctive** (refinements combined with an `OR`). You can modify the conjunctive/disjunctive status of a facet by calling `setFacet(withName:disjunctive:)`.

When a search is triggered, the searcher will build the facet filters according to the refinements and the
conjunctive/disjunctive state of each facet.

**Note:** *You still need to specify the list of all facets via the `facets` search parameter.*

**Note:** *The `filters` and `facetFilters` search parameters will be overridden by the facet refinements; any manually specified value will be lost.*


### Numeric filters

The search parameters also provide tools to easily manipulate numeric filters, through the notion of **numeric refinements**. A numeric refinement is basically made of an attribute name (the left operand), a comparison operator and a value (right operand). Optionally, the expression can be negated.

The numeric refinement handling methods work in a very similar fashion to the facet refinements (see above):

- A given numeric attribute can be treated as either conjunctive (the default) or disjunctive. The conjunctive/disjunctive status is modified via `setNumeric(withName:disjunctive:)`.

- Numeric refinements are edited via `addNumericRefinement(...)` and `removeNumericRefinement(...)`.

**Note:** *The `filters` and `numericFilters` search parameters will be overridden by the numeric refinements; any manually specified value will be lost.*


## Events

The `Searcher` class emits notifications through `NSNotificationCenter` on various events of its lifecycle:

- `Searcher.SearchNotification` when a new request is fired
- `Searcher.ResultNotification` when a successful response is received
- `Searcher.ErrorNotification` when an erroneous response is received
- `SearcherRefinementChangeNotification` when numeric and facet refinements are changed

You may subscribe to these notifications to react on different events without having to explicitly write a result handler.
