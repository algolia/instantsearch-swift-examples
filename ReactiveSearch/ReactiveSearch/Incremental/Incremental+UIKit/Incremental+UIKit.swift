//
//  Incremental+UIKit.swift
//  Incremental
//
//  Created by Chris Eidhof on 22.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

extension IBox where V: UIView {
    public func addSubview<S>(_ subview: IBox<S>, constraints: [Constraint] = []) where S: UIView {
        disposables.append(subview)
        unbox.addSubview(subview.unbox)
        if !constraints.isEmpty {
            subview.unbox.translatesAutoresizingMaskIntoConstraints = false
            for c in constraints {
                c(unbox, subview.unbox).isActive = true
            }
        }
    }
    
    public func bindSubviews<View: UIView>(_ iArray: I<ArrayWithHistory<IBox<View>>>) {
        
        disposables.append(iArray.observe { value in // todo owernship of self?
            assert(self.unbox.subviews.isEmpty)
            for view in value.initial { self.unbox.addSubview(view.unbox) }
            value.changes.read { changeList in
                return changeList.reduce(eq: { _,_ in false }, initial: (), combine: { (change, _) in
                    switch change {
                    case let .insert(subview, index):
                        self.disposables.append(subview)
                        self.unbox.insertSubview(subview.unbox, at: index)
                    case .remove(let index):
                        // todo remove disposable!
                        self.unbox.subviews[index].removeFromSuperview()
                    }
                    return ()
                })
            }
        })
    }
    
    public var cast: IBox<UIView> {
        return map { $0 }
    }
}

class TargetAction: NSObject {
    let callback: () -> ()
    init(_ callback: @escaping () -> ()) {
        self.callback = callback
    }
    @objc func action(_ sender: AnyObject) {
        callback()
    }
}

