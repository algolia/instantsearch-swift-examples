//
//  TableViews.swift
//  Incremental
//
//  Created by Chris Eidhof on 27.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit

final class TableVC<A>: UITableViewController {
    var items: [A] = []
    let configure: (UITableViewCell,A) -> ()
    let didSelect: ((A) -> ())?
    
    init(_ items: [A], didSelect: ((A) -> ())? = nil, configure: @escaping (UITableViewCell,A) -> ()) {
        self.items = items
        self.configure = configure
        self.didSelect = didSelect
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Identifier")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect?(items[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Identifier")!
        configure(cell, items[indexPath.row])
        return cell
    }
}

extension TableVC where A: Equatable {
    func apply(_ change: ArrayChange<A>) {
        items.apply(change)
        switch change {
        case let .insert(_, at: index):
            let indexPath = IndexPath(row: index, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
        case let .remove(at: index):
            let indexPath = IndexPath(row: index, section: 0)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

public func tableViewController<A>(items value: ArrayWithHistory<A>, didSelect: ((A) -> ())? = nil, configure: @escaping (UITableViewCell, A) -> ()) -> IBox<UITableViewController> {
    let tableVC = TableVC([], didSelect: didSelect, configure: configure)
    let box = IBox<UITableViewController>(tableVC)
    box.disposables.append(value.observe(current: {
        tableVC.items = $0
    }, handleChange: { change in
        tableVC.apply(change)
    }))
    return box
}

public func tableViewController<A>(items value: I<[A]>, didSelect: ((A) -> ())? = nil,  configure: @escaping (UITableViewCell, A) -> ()) -> IBox<UITableViewController> {
    let tableVC = TableVC([], didSelect: didSelect, configure: configure)
    let box = IBox<UITableViewController>(tableVC)
    box.disposables.append(value.observe {
        tableVC.items = $0
        tableVC.tableView.reloadData()
    })
    return box
}
