//
//  SearchHeaderView.swift
//  ReactiveSearch
//
//  Created by Robert Mogos on 09/03/2018.
//  Copyright © 2018 Robert Mogos. All rights reserved.
//

import UIKit

class SearchHeaderView: UIView {
  @IBOutlet weak var filtersButton: UIButton!
  @IBOutlet weak var productsCountLabel: UILabel!
  
  var itemsCount: Int = 0 {
    didSet {
      productsCountLabel.text = "\(itemsCount) products found"
    }
  }
}
