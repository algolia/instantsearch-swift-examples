//
//  StackViews.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

extension IBox where V == UIStackView {
    public convenience init<S>(arrangedSubviews: [IBox<S>]) where S: UIView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews.map { $0.unbox })
        self.init(stackView)
        disposables.append(arrangedSubviews)
    }
    
    public convenience init<S>(arrangedSubviews: ArrayWithHistory<IBox<S>>) where S: UIView {
        let stackView = UIStackView(arrangedSubviews: [])
        self.init(stackView)
        self.bindArrangedSubviews(to: arrangedSubviews)
    }
    
}

extension IBox where V: UIStackView {
    
    func addArrangedSubview<View: UIView>(_ i: IBox<View>) {
        disposables.append(i)
        unbox.addArrangedSubview(i.unbox)
    }
    
    func insertArrangedSubview<View: UIView>(_ subview: IBox<View>, at index: Int) {
        disposables.append(subview)
        unbox.insertArrangedSubview(subview.unbox, at: index)
    }
    
    func removeArrangedSubview<V: UIView>(_ subview: V) {
        guard let index = disposables.index(where: { ($0 as? IBox<V>)?.unbox === subview }) else {
            assertionFailure("Can't find subview.")
            return
        }
        disposables.remove(at: index)
        unbox.removeArrangedSubview(subview)
    }

    public func bindArrangedSubviews<Subview: UIView>(to value: ArrayWithHistory<IBox<Subview>>, animationDuration duration: TimeInterval = 0.2) {
        self.disposables.append(value.observe(current: { initialArrangedSubviews in
            assert(self.unbox.arrangedSubviews == [])
            for v in initialArrangedSubviews {
                self.addArrangedSubview(v)
            }
        }) {
            switch $0 {
            case let .insert(v, at: i):
                v.unbox.isHidden = true
                self.insertArrangedSubview(v, at: i)
                // todo also add v to disposables!
                UIView.animate(withDuration: duration) {
                    v.unbox.isHidden = false
                }
            case .remove(at: let i):
                let v: Subview = self.unbox.arrangedSubviews.filter { !$0.isHidden }[i] as! Subview
                UIView.animate(withDuration: duration, animations: {
                    v.isHidden = true
                }, completion: { _ in
                    self.removeArrangedSubview(v)
                })
            }
        })
    }
}

public func stackView<V: UIView>(arrangedSubviews: [IBox<V>], axis: UILayoutConstraintAxis = .vertical, spacing: I<CGFloat> = I(constant: 10)) -> IBox<UIView> {
    let stackView = IBox<UIStackView>(arrangedSubviews: arrangedSubviews)
    stackView.unbox.axis = axis
    stackView.bind(spacing, to: \.spacing)
    return stackView.cast
}


