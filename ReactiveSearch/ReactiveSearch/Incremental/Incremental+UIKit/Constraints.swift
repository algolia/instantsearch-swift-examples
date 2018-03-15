//
//  Constraints.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

public typealias Constraint = (_ parent: UIView, _ child: UIView) -> NSLayoutConstraint

public func equalTop(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        // todo not sure if this is a good idea
        if #available(iOS 11.0, *) {
            return parent.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.topAnchor, constant: offset)
        } else {
            return parent.topAnchor.constraint(equalTo: child.topAnchor, constant: offset)
        }
    }
}

public func equalLeading(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        parent.leadingAnchor.constraint(equalTo: child.leadingAnchor, constant: offset)
    }
}
public func equalTrailing(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        parent.trailingAnchor.constraint(equalTo: child.trailingAnchor, constant: offset)
    }
}

public func equalCenterX(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        parent.centerXAnchor.constraint(equalTo: child.centerXAnchor, constant: offset)
    }
}

public func equalCenterY(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        parent.centerYAnchor.constraint(equalTo: child.centerYAnchor, constant: offset)
    }
}

public func equalRight(offset: CGFloat = 0) -> Constraint {
    return { parent, child in
        parent.rightAnchor.constraint(equalTo: child.rightAnchor, constant: offset)
    }
}
