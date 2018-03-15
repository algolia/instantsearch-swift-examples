//
//  TextField.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

public func textField(text: I<String>, backgroundColor: I<UIColor?> = I(constant: nil), onChange: @escaping (String?) -> ()) -> IBox<UIView> {
    let textField = UITextField()
    let result = IBox(textField)
    result.bind(text, to: \.text)
    result.bind(backgroundColor, to: \.backgroundColor)
    
    let ta = TargetAction { onChange(textField.text) }
    textField.addTarget(ta, action: #selector(TargetAction.action(_:)), for: .editingChanged)
    result.disposables.append(ta)
    return result.cast
}
