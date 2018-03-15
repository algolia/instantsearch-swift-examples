---
title: Highlighting
layout: guide.mustache
---

# Highlighting

The `Highlighter` class is in charge of parsing highlight result values (as returned by the Search API in the `_highlightResults` attribute of every hit) and render them into a rich text string (an `NSAttributedString` instance).

## Configuration

### Styles

When you instantiate a highlighter, you specify a set of **text attributes** that will be applied to highlighted portions. For example, the following code will give you truly ugly red-on-yellow highlights:

```swift
let highlighter = Highlighter(highlightAttrs: [
    NSForegroundColorAttributeName: UIColor.red,
    NSBackgroundColorAttributeName: UIColor.yellow,
]
```

### Tags

By default, the highlighter is set to recognized `<em>` tags, which are the default tags used by the Search API to mark up highlights. However, you can easily override that to a custom value.

**Note:** *In that case, make sure that it matches the values for `highlightPreTag` and `highlightPostTag` in your search query (or your index's default)!*

```swift
highlighter.preTag = "<mark>"
highlighter.postTag = "</mark>"
```

## Rendering

Once the highlighter is configured, rendering highlights is just a matter of calling `render(text:)`. The real trick is to retrieve the highlighted value from the JSON... Fortunately, the `SearchResults` class makes it easy:

```swift
let searchResults: SearchResults = ... // whatever was received by the result handler
let index: Int = ... // index of the hit you want to retrieve
if let highlightResult = searchResults.highlightResult(at: index, path: "attribute_name") {
    if let highlightValue = highlightResult.value {
        let highlightedString = highlighter.render(text: highlightValue)
    }
}
```

## Inverse highlighting

In most cases, you want to highlight parts of the text that matched the search query, to show users why the results are relevant to their search. There may be cases, however, where **inverse highlighting** is more adapted.

Let's consider **query suggestions**: as the user types, you are suggesting queries that contain the text already entered. In that case, highlighting the matched text does not bring any useful information, as it is the same for all suggestions. What is much more relevant is to highlight *the remaining parts*, i.e. the additional text supplied by each suggestion.

For example, when searching for "star", instead of displaying:

- **star** wars
- **star** trek

... you could display:

- star **wars**
- star **trek**

This is the goal of the `inverseHighlights(in:)` function. Just supply a string with regular highlights, and it will convert highlighted parts into non-highlighted parts and vice versa.

```swift
let highlighter = /* your highlighter */
print(highlighter.inverseHighlights(in: "<em>star</em> wars"))
// ... will print `star<em> wars</em>`
```
