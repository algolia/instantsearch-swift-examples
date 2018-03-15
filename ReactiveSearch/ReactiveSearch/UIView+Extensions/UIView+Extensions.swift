//
//  UIView+Extensions.swift
//  ReactiveSearch
//
//  Created by Robert Mogos on 09/03/2018.
//  Copyright © 2018 Robert Mogos. All rights reserved.
//

import Foundation
import UIKit
import InstantSearchCore

private var highlightedBackgroundColorKey: Void?
private var isHighlightingInversedKey: Void?

/// Extension menthods for UILabel used to highlight hits
extension UILabel {
  
  /// The highlighted background color of the string that matches the search query in Algolia's index.
  /// + Note: This can only be used with the InstantSearch library.
  @objc public var highlightedBackgroundColor: UIColor? {
    get {
      return objc_getAssociatedObject(self, &highlightedBackgroundColorKey) as? UIColor
    }
    set(newValue) {
      objc_setAssociatedObject(self, &highlightedBackgroundColorKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
  }
  
  /// Whether or not the highlighted background color of the string that matches the search query is inverted or not.
  /// + Note: This can only be used with the InstantSearch library.
  @objc public var isHighlightingInversed: Bool {
    get {
      guard let isHighlightingInversed = objc_getAssociatedObject(self, &isHighlightingInversedKey) as? Bool else {
        return false
      }
      
      return isHighlightingInversed
    }
    set(newValue) {
      objc_setAssociatedObject(self, &isHighlightingInversedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
  }
  
  /// The text to be highlighte. This should be the string that matches the search query in Algolia's index.
  /// + Note: This can only be used with the InstantSearch library.
  @objc public var highlightedText: String? {
    get {
      return attributedText?.string
    }
    set {
      guard let newValue = newValue, !newValue.isEmpty else { return }
      
      let text = isHighlightingInversed ? Highlighter(highlightAttrs: [:]).inverseHighlights(in: newValue) : newValue
      
      let textColor = highlightedTextColor ?? self.tintColor ?? UIColor.blue
      let backgroundColor = highlightedBackgroundColor ?? UIColor.clear
      
      attributedText = Highlighter(highlightAttrs: [NSAttributedStringKey.foregroundColor: textColor,
                                                    NSAttributedStringKey.backgroundColor: backgroundColor]).render(text: text)
    }
  }
}

class NibError: Error {
  
}

extension UIView {
  class func loadNib<T>(_ nibName: String) -> T? {
    let nib = UINib(nibName: nibName, bundle: nil)
    guard let view = nib.instantiate(withOwner: self, options: nil).first as? T else {
      return nil
    }
    return view
  }
}
