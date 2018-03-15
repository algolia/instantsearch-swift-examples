---
title: History management
layout: guide.mustache
---

# History management

InstantSearch Core provides facilities to record the history of search queries, and query this history.

## Recording queries

Recording is handled by the `HistoryRecorder` class, which observes a single `Searcher` and updates a `History` accordingly.

By default, the recorder debounces queries to avoid triggering too many calls to the history. (This can be especially useful if the history is handled remotely, i.e. recording queries involves network calls.) Note that debouncing alone is usually not enough to deduplicate search queries in an as-you-type setting, i.e. avoid prefixes of a search to be recorded. This has to be handled by the history itself.

```swift
let searcher = /* your searcher */
let history = LocalHistory()
let recorder = HistoryRecorder(searcher: searcher, history: history)
```

## Searching the history

The `History` protocol provides a `search(...)` method to search the history for matching queries. It returns an array of `HistoryHit` instances. Each hit is a combination of search parameters ready to use in a call to `Searcher.search(...)` (the `params` property), and a highlighted description of the hit (the `highlightedText` property). Typically, the description contains the full text query with parts matching the search highlighted.

```swift
let params = SearchParameters()
params.query = "star"
let hits = history.search(query: params)
for hit in hits {
    print("\(hit.highlightedText)")
}
```

Possible output:

```html
<em>star</em> wars
rock <em>star</em>s
```

## Data sinks

### Local history

InstantSearch Core provides a default implementation of the `History` protocol, the `LocalHistory` class, that records searches locally, optionally persisting them on disk.

You just need to specify the path to the file you want the history to reside:

```swift
// Store the history in a `history.dat` file inside the `Application Support` directory.
let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
let historyFile = URL(fileURLWithPath: appSupportDir).appendingPathComponent("history.dat").path
let history = LocalHistory(filePath: historyFile)
```

### Plugging your own implementation

Let's say that you want to share the search history of your users across their devices. In that case, you need to send the history entries to your back-end.

This can easily be achieved by implementing the `History` protocol, which contains only two methods:

- the `add(...)` method to record the queries;
- the `search(...)` method to search inside the history.
