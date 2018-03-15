//
//  ViewController.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

public func viewController<V: UIView>(rootView: IBox<V>, constraints: [Constraint] = []) -> IBox<UIViewController> {
    let vc = UIViewController()
    let box = IBox(vc)
    vc.view.addSubview(rootView.unbox)
    vc.view.backgroundColor = .white
    box.disposables.append(rootView)
    rootView.unbox.translatesAutoresizingMaskIntoConstraints = false
    for c in constraints {
        c(vc.view, rootView.unbox).isActive = true
    }
    return box
}

