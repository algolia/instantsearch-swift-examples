//
//  Copyright (c) 2016-2017 Algolia
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

import Foundation


/// Pluggable request strategy.
/// A strategy acts as an optional delegate to one or more `Searcher` instances and decides how to transform logical
/// search intents (i.e. calls to `Searcher.search(...)`) into actual search requests.
///
/// ## Implementation notes
///
/// A strategy should be able to work with multiple searchers. It is the case for strategies provided by this library.
/// When implementing your own strategy, either follow this rule... or restrain from passing the same strategy to
/// multiple searchers.
///
@objc public protocol RequestStrategy: class {

    /// Ask the strategy to perform a search.
    /// Whether the search will be performed or not, immediately or not, is at the discretion of the strategy.
    ///
    /// - parameter searcher: Searcher asking for the search.
    /// - parameter userInfo: Search metadata, as passed to `Searcher.search(...)`. May influence the strategy.
    /// - parameter callback: Block to be called by the strategy if and when it decides to search.
    ///                       The argument is typically the `userInfo` parameter, although it may be altered by the
    ///                       strategy as it sees fit.
    ///
    @objc func performSearch(from searcher: Searcher, userInfo: [String: Any], with callback: @escaping ([String: Any]) -> Void)
}
