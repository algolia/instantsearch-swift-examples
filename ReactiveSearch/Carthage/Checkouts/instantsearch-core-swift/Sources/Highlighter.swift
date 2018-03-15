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

import Foundation


/// Renders marked up text into attributed strings with markup removed and the visual attributes applied to highlights.
///
@objc public class Highlighter: NSObject {
    // MARK: Properties
    
    /// Visual attributes to apply to the highlights.
    @objc public var highlightAttrs: [NSAttributedStringKey: Any]
    
    /// Markup identifying the beginning of a highlight. Defaults to `<em>`.
    @objc public var preTag: String = "<em>"

    /// Markup identifying the end of a highlight. Defaults to `</em>`.
    @objc public var postTag: String = "</em>"

    /// Whether the markup is case sensitive. Defaults to `false`.
    @objc public var caseSensitive: Bool = false

    // MARK: Initialization

    /// Create a new highlighter with the specified text attributes for highlights.
    ///
    /// - parameter highlightAttrs: Text attributes to apply to highlights. The content must be suitable for use within
    ///   an `NSAttributedString`.
    ///
    @objc public init(highlightAttrs: [NSAttributedStringKey: Any]) {
        self.highlightAttrs = highlightAttrs
    }

    // MARK: Rendering

    /// Render the specified text.
    ///
    /// - parameter text: The marked up text to render.
    /// - returns: An atributed string with highlights outlined.
    ///
    @objc(renderText:)
    public func render(text: String) -> NSAttributedString {
        let newText = NSMutableString(string: text)
        var rangesToHighlight = [NSRange]()
        
        // Remove markup and identify ranges to highlight at the same time.
        while true {
            let matchBegin = newText.range(of: preTag, options: caseSensitive ? [] : [.caseInsensitive])
            if matchBegin.location != NSNotFound {
                newText.deleteCharacters(in: matchBegin)
                let range = NSRange(location: matchBegin.location, length: newText.length - matchBegin.location)
                let matchEnd = newText.range(of: postTag, options: .caseInsensitive, range: range)
                if matchEnd.location != NSNotFound {
                    newText.deleteCharacters(in: matchEnd)
                    rangesToHighlight.append(NSRange(location: matchBegin.location, length: matchEnd.location - matchBegin.location))
                }
            } else {
                break
            }
        }
        
        // Apply the specified attributes to the highlighted ranges.
        let attributedString = NSMutableAttributedString(string: String(newText))
        for range in rangesToHighlight {
            attributedString.addAttributes(highlightAttrs, range: range)
        }
        return attributedString
    }
    
    /// Inverse highlights in a text.
    /// The highlighted parts lose highlighting, and the not highlighted parts become highlighted.
    ///
    /// - parameter text: Text to inverse highlight in.
    /// - returns: Text with inversed highlights.
    ///
    @objc(inverseHighlightsInText:)
    public func inverseHighlights(in text: String) -> String {
        assert(preTag != postTag)
        var result = ""
        var flushIndex = text.startIndex
        while let preRange = text.range(of: preTag, options: [], range: flushIndex ..< text.endIndex) {
            // If the closing tag is not found, assume the end of the string to be the end of the markup.
            let postRange = text.range(of: postTag, options: [], range: preRange.upperBound ..< text.endIndex) ?? text.endIndex ..< text.endIndex
            if flushIndex < preRange.lowerBound {
                result += preTag
                result += text[flushIndex ..< preRange.lowerBound]
                result += postTag
            }
            result += text[preRange.upperBound ..< postRange.lowerBound]
            flushIndex = postRange.upperBound
        }
        if flushIndex < text.endIndex {
            result += preTag
            result += text[flushIndex ..< text.endIndex]
            result += postTag
        }
        return result
    }
}
