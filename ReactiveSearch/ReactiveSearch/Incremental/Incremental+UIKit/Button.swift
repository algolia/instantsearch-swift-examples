//
//  Button.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

public func button(type: UIButtonType = .custom, title: I<String>, backgroundColor: I<UIColor> = I(constant: .white), titleColor: I<UIColor?> = I(constant: nil), onTap: @escaping () -> ()) -> IBox<UIButton> {
    let result = IBox<UIButton>(UIButton(type: type))
    result.bind(backgroundColor, to: \.backgroundColor)
    result.observe(value: title, onChange: { $0.setTitle($1, for: .normal) })
    result.observe(value: titleColor, onChange: { $0.setTitleColor($1, for: .normal)})
    let ta = TargetAction(onTap)
    result.unbox.addTarget(ta, action: #selector(TargetAction.action(_:)), for: .touchUpInside)
    result.disposables.append(ta)
    return result
}

// todo dry
public func button(type: UIButtonType = .custom, titleImage: I<UIImage>, backgroundColor: I<UIColor> = I(constant: .white), titleColor: I<UIColor?> = I(constant: nil), onTap: @escaping () -> ()) -> IBox<UIButton> {
    let result = IBox<UIButton>(UIButton(type: type))
    result.bind(backgroundColor, to: \.backgroundColor)
    result.observe(value: titleImage, onChange: { $0.setImage($1, for: .normal) })
    result.observe(value: titleColor, onChange: { $0.setTitleColor($1, for: .normal)})
    let ta = TargetAction(onTap)
    result.unbox.addTarget(ta, action: #selector(TargetAction.action(_:)), for: .touchUpInside)
    result.disposables.append(ta)
    return result
}
