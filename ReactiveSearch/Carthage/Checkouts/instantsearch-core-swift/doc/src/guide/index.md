---
title: Overview
layout: guide.mustache
---

# Overview

## Rationale

While the API Client covers the entire feature set of the Search API, it primarily aims at efficiency and simplicity. It does not provide much beyond raw search requests.

However, when building a search UI, especially in an as-you-type setting, more work is usually required that just issuing requests. InstantSearch takes you one step further by focusing on **search session** management.


## Features

The central class of InstantSearch is the `Searcher` class, which manages searches on a given index. It takes care of properly **sequencing** received results (which may come out-of-order due to network unpredictability) and **pagination**. It also provides tools to manipulate **facet filters** and **numeric filters**.

The `Highlighter` class takes care of transforming marked up text such as found in search result highlights into attributed text suitable for display.

Other miscellaneous utilities are provided as well.

**Note:** *InstantSearch Core is UI-agnostic.* Although some features (such as highlight rendering) are only useful in the context of a user interface, the library has no dependencies on a specific UI framework. For example, it can indiscriminately be used on iOS with UIKit or macOS with AppKit. It has no system dependencies beyond Foundation (see below).


## Supported platforms

The library is written in Swift, but is fully compatible with Objective-C.

It supports every platform that the [API Client](https://github.com/algolia/algoliasearch-client-swift) supports (at the time of writing: iOS, macOS and tvOS).


## Dependencies

This module requires:

- Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift).
- Apple's Foundation framework.
