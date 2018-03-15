---
title: Request strategy
layout: guide.mustache
---

# Request strategy

## Overview

By default, a `Searcher` will launch a request every time you call `search(...)`. That's what you want, right?

Well, not always. When network conditions are bad, for example (high latency, poor bandwidth, packet loss...), the network may not be able to cope with as-you-type search, which could lead to a poor user experience.

That's why the `Searcher` class accepts an optional **strategy delegate** that, when provided, will take care of deciding how to perform searches. This delegate can decide to drop requests, to throttle them, or even alter their metadata.

## Adaptive network

### Rationale

The library provides one request strategy implementation: `AdaptiveNetworkStrategy`. This strategy monitors the response time of every request, and based on the observed response times, switches between various modes: **realtime**, **throttled** and **manual**.

In **realtime mode**, which is the default, all requests are fired immediately. This is typically what you want in an as-you-type search context, and provides the optimal user experience when the network conditions are good.

As soon as the network starts to degrade, however, things get more complicated: not only may the requests take too long to complete, but if the bandwidth is not sufficient, the response time may even get slower and slower, as requests stack up inside the pipeline. To fight this effect, the **throttled mode** delays requests, dropping them along the way, to ensure a maximum throughput. Furthermore, the throttling delay is dynamically adjusted so that the search throughput more or less matches the current network's capabilities.

If the network is very bad, though, as-you-type search stops being the right option altogether. Instead of having users stare at a spinning wheel forever, it's better to disable as-you-type, and inform the users that they need to explicitly submit their searches. That's what the **manual mode** does: all non-final searches are dropped.

### Usage

Using the adaptive network strategy first requires monitoring response times using a `ResponseTimeStats`. Then, you create a new `AdaptiveNetworkStrategy` using those statistics, and assigning it to a `Searcher`:

```swift
let searcher = /* your searcher */
let stats = ResponseTimeStats(searcher: searcher)
let strategy = AdaptiveNetworkStrategy(stats: stats)
searcher.strategy = strategy
```

**Note:** *As is customary for delegates, a `Searcher` does not retain its strategy. You must therefore ensure that its lifetime exceeds that of the searcher.*


## Writing your own strategy

Implementing your own strategy is just a matter of implementing the `RequestStrategy` protocol, which contains only one method: `performSearch(from:userInfo:with:)`. The `Searcher` calls the strategy when the `search(...)` method is invoked, providing the search metadata via the `userInfo` parameter, and a block that the strategy should call when it decides to perform the search.
