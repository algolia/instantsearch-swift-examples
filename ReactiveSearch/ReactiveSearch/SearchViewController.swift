//
//  SearchViewController.swift
//  ReactiveSearch
//
//  Created by Robert Mogos on 02/03/2018.
//  Copyright © 2018 Robert Mogos. All rights reserved.
//

import UIKit
import InstantSearchCore

final class Box<A> {
  let unbox: A
  var references: [Any] = []
  
  init(_ value: A) {
    self.unbox = value
  }
}

//extension Box where A: UILabel {
//  func bindText(to text: I<String>) {
//    let disposable = text.observe { [unowned self] newText in
//      self.unbox.text = newText
//    }
//    references.append(disposable)
//  }
//}
//
//extension Box where A: SearchHeaderView {
//  func bindHitCounts(to counts:I<Int>) {
//    let disposable = counts.observe { [unowned self] newNbHits in
//      self.unbox.itemsCount = newNbHits
//    }
//    references.append(disposable)
//  }
//
//  func bindFilterEnabled(to enabled:I<Bool>) {
//    let disposable = enabled.observe { [unowned self] enabF in
//      self.unbox.filtersButton.isEnabled = enabF
//    }
//    references.append(disposable)
//  }
//}

extension Box where A: UITextField {
  func onChange(_ action: @escaping(String?) -> ()) {
    let ta = TargetAction { action(self.unbox.text) }
    self.unbox.addTarget(ta, action: #selector(TargetAction.action(_:)), for: .editingChanged)
    references.append(ta)
  }
}
private var rsAssociationKey: UInt8 = 0


extension UISearchBar {
  var proxyDelegate: UISearchBarDelegate? {
    get {
      return objc_getAssociatedObject(self, &rsAssociationKey) as? UISearchBarDelegate
    }
    set(newValue) {
      objc_setAssociatedObject(self, &rsAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }
  }
}

extension Box where A: UISearchBar {
  
  
  func onTextDidChange(_ action: @escaping(String?) -> ()) {
    
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    guard let proxyDelegate = self.unbox.proxyDelegate else {
      return
    }
    proxyDelegate.searchBar?(searchBar, textDidChange: searchText)
  }
}

extension Box {
  func bind<Property>(_ keyPath: ReferenceWritableKeyPath<A, Property>, to value: I<Property>) {
    references.append(value.observe { [unowned self] newValue in
      self.unbox[keyPath: keyPath] = newValue
    })
  }
}


class SearchViewController: UITableViewController {
  let searchBar = UISearchBar()
  let searchBarBox = Box(searchBar)
  
  var headerView: SearchHeaderView!
  var searchResults = ReactiveSearch.shared.searchResults
  var observer: Disposable!
  
  private var headerViewBox: Box<SearchHeaderView>!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.titleView = searchBar
    //searchBar.delegate = self
    self.tableView.register(UINib.init(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "recordCell")
    headerView = SearchHeaderView.loadNib("SearchHeaderView")
    tableView.tableHeaderView = headerView
    
    headerViewBox = Box(headerView)
    observer = searchResults.observe { [weak self] _ in
      self?.tableView.reloadData()
    }
    
    headerViewBox.bind(\.itemsCount, to: searchResults.map { $0.nbHits })
    headerViewBox.bind(\.filtersButton.isEnabled, to: searchResults.map { $0.nbHits > 0 })
    //    searchBarBox.onTextDidChange { [weak self] newText in
    //      ReactiveSearch.shared.search(with: newText)
    //    }
    
    ReactiveSearch.shared.search()
  }
}

extension SearchViewController: UISearchBarDelegate {
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    ReactiveSearch.shared.search(with: searchText)
  }
}

extension SearchViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.value.allHits.count
  }
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath) as! ItemCell
    let item = searchResults.value.allHits[indexPath.row]
    cell.item = ItemRecord(json: item)
    
    let threshold = 5
    if indexPath.row >= (searchResults.value.allHits.count) - threshold {
      ReactiveSearch.shared.loadMore()
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.navigationController?.pushViewController(SearchViewController(), animated: true)
  }
}

extension SearchViewController {
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    searchBar.resignFirstResponder()
  }
}

