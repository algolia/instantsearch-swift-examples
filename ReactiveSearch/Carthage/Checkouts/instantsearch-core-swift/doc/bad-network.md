Bad network
===========


## Overview

The Search Helper provides an **adaptive strategy** for bad network conditions, through the `SearchStrategist` class.
A search strategist constantly monitors response times observed by a `Searcher` instance, and reacts by switching its
strategy between the following modes:

- **Realtime search:** full as-you-type search: each keystroke immediately turns into a request. For this mode to work,
  the response time must be below the delay between two keystrokes (around 300 ms in average).

- **Throttled search:** still an as-you-type search, but requests are delayed and merged before being sent: if many
  keystrokes are issued rapidly, only the last one will turn into a request. This mode works well if response time is
  slower than delays between keystrokes, but still reasonable (from 300 ms to 1 s).

- **Manual search:** the user has to specifically ask for a search for a request to be sent (e.g. by hitting a "Search"
  button).

When switching to manual search, it should be made obvious to the user that his/her action is now required for a
search to be triggered. For example, the result list can be cleared, with a placeholder such as "Press 'Search' to
see results".

The strategist starts with the realtime strategy. It also falls back to this strategy whenever its statistics are too
old. This guarantees that it will not remain stuck in a suboptimal strategy if the network conditions have improved.


## Typical session

Let's examine how a strategist may switch between modes over a typical search session.

The strategist is initially in the `realtime` strategy. The network is good, everything goes fine.

Let's imagine that the network conditions suddenly degrade. The user types a new letter; a request is sent, but this
request will actually take a long time. The strategist cannot know it yet, of course. However, after the first
threshold is expired, the strategist revises its strategy. And when the second threshold is expired, the strategist
revises its strategy again. Now, *one* request may not be enough to trigger a strategy change, because the strategist
uses an average to smooth out irregularities. But as soon as enough requests take too much time, the strategy changes.

When the strategy changes to `throttled`, requests start being debounced, but we are still in an as-you-type setting.
Previous, non-debounced requests are left running.
