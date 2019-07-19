//
//  ViewController.swift
//  ecommerce
//
//  Created by Guy Daher on 02/02/2017.
//  Copyright © 2017 Guy Daher. All rights reserved.
//

import UIKit
import InstantSearch

class ItemTableViewController: HitsTableViewController {
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var tableView: HitsTableWidget!
    @IBOutlet weak var searchBarNavigationItem: UINavigationItem!
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var nbHitsLabel: UILabel!
    
//    var hitsController: HitsController!
  
    private var searchBarWidget: SearchBarWidget?
//    var searchController: UISearchController!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        configureNavBar()
        configureToolBar()
        configureSearchController()
        configureTable()
        configureInstantSearch()
        hitsTableView = tableView
//        hitsController = HitsController(table: tableView)
//        tableView.dataSource = hitsController
//        tableView.delegate = hitsController
//        hitsController.tableDataSource = self
    }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchBarView.becomeFirstResponder()
  }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, containing hit: [String : Any]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath) as! ItemCell
        
        cell.item = ItemRecord(json: hit)
        cell.backgroundColor = ColorConstants.tableColor
        
        return cell
    }
    
    // MARK: Helper methods for configuring each component of the table
    
    func configureInstantSearch() {
//        InstantSearch.shared.register(searchController: searchController)
        InstantSearch.shared.register(widget: searchBarWidget!)
        InstantSearch.shared.registerAllWidgets(in: self.view)
    }
    
    func configureTable() {
        tableView.delegate = self
        tableView.backgroundColor = ColorConstants.tableColor
    }
    
    func configureNavBar() {
        navigationController?.navigationBar.barTintColor = ColorConstants.barBackgroundColor
        navigationController?.navigationBar.isTranslucent = false
      navigationController?.navigationBar.titleTextAttributes = [kCTForegroundColorAttributeName : ColorConstants.barTextColor] as [NSAttributedString.Key : Any]
    }
    
    func configureToolBar() {
        topBarView.backgroundColor = ColorConstants.tableColor
    }
    
    func configureSearchController() {
        // Initialize and perform a minimum configuration to the search controller.
//        searchController = UISearchController(searchResultsController: nil)
//
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.hidesNavigationBarDuringPresentation = false
//
//        searchController.searchBar.placeholder = "Search items"
//        searchController.searchBar.sizeToFit()
//
//        searchController.searchBar.barTintColor = ColorConstants.barBackgroundColor
//        searchController.searchBar.isTranslucent = false
//        searchController.searchBar.layer.cornerRadius = 1.0
//        searchController.searchBar.clipsToBounds = true
//        searchBarView.addSubview(searchBarWidget!)
      searchBarWidget = SearchBarWidget(frame: searchBarView.frame)
      searchBarWidget?.placeholder = "Search items"
      searchBarWidget?.sizeToFit()
      
      searchBarWidget?.barTintColor = UIColor.clear
      searchBarWidget?.isTranslucent = true
      searchBarWidget?.layer.cornerRadius = 1.0
      searchBarWidget?.clipsToBounds = true
      searchBarWidget?.searchBarStyle = .minimal
      searchBarWidget?.tintColor = UIColor(red:1.00, green:0.64, blue:0.19, alpha:1.0)
      
//      searchBarWidget?.setMagnifyingGlassColorTo(color: .white)
//      searchBarWidget?.setPlaceholderTextColorTo(color: .white)
//      searchBarWidget?.setCancelColor(color: .white)
      searchBarView.addSubview(searchBarWidget!)
      searchBarView.bringSubviewToFront(searchBarWidget!)
//      topBarView.backgroundColor = .red
//      searchBarView.backgroundColor = .green
      searchBarWidget!.frame = .init(x: 0, y: 0, width: searchBarView.frame.width, height: searchBarView.frame.height) //.init(x: -100, y: 0, width: 320, height: 44)
    }
}
