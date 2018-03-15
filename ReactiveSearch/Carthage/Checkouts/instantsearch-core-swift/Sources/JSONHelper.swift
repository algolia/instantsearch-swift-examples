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


/// Various helpers to deal with JSON data.
///
internal class JSONHelper {
    // NOTE: Should be an extension, but restricting a generic type non the non-protocol type String does not compile.
    
    /// Get the value for an attribute with a "deep" path (dot notation).
    /// Example: asking for "foo.bar" will retrieve the "bar" attribute of the "foo" attribute, provided that the
    /// latter exists and is a dictionary.
    ///
    /// - parameter json: The root JSON object.
    /// - parameter path: Path of the attribute to retrieve, in dot notation.
    /// - returns: The corresponding value, or nil if it does not exist.
    ///
    internal static func valueForKeyPath(json: [String: Any], path: String) -> Any? {
        var value: Any = json
        for name in path.components(separatedBy: ".") {
            if let newValue = (value as? [String: Any])?[name] {
                value = newValue
            } else {
                return nil
            }
        }
        return value
    }
}
