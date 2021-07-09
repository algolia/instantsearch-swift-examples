//
//  DemoFactory.swift
//  DemoDirectory
//
//  Created by Vladislav Fitc on 09/06/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class DemoFactory {
  
  func viewController(for demo: Demo) throws -> UIViewController {
    
    guard let demoID = Demo.ID(rawValue: demo.objectID) else {
      throw Error.demoNotImplemented
    }
    
    let viewController: UIViewController
    
    switch demoID {
    case .singleIndex:
      viewController = SingleIndexDemoViewController()
      
    case .sffv:
      viewController = FacetSearchDemoViewController()
      
    case .toggle:
      viewController = ToggleDemoViewController()
      
    case .toggleDefault:
      viewController = ToggleDefaultDemoViewController()
      
    case .DynamicFacetList:
      viewController = DynamicFacetListSwiftUIDemoViewController()
      
    case .facetList:
      viewController = RefinementListDemoViewController()
      
    case .facetListPersistentSelection:
      viewController = RefinementPersistentListDemoViewController()
      
    case .segmented:
      viewController = SegmentedDemoViewController()
      
    case .filterNumericComparison:
      viewController = FilterNumericComparisonDemoViewController()
      
    case .filterNumericRange:
      viewController = FilterNumericRangeDemoViewController()
      
    case .filterRating:
      viewController = RatingViewController()
      
    case .sortBy:
      viewController = IndexSegmentDemoViewController()
      
    case .currentFilters:
      viewController = CurrentFiltersDemoViewController()
      
    case .clearFilters:
      viewController = ClearFiltersDemoViewController()
      
    case .multiIndex:
      viewController = MultiIndexDemoViewController()
    //MultiIndexHitsConnectorSearchViewController()
    //
    
    case .facetFilterList:
      viewController = FilterListDemo.facet()
      
    case .numericFilterList:
      viewController = FilterListDemo.numeric()
      
    case .tagFilterList:
      viewController = FilterListDemo.tag()
      
    case .searchOnSubmit:
      viewController = SearchInputDemoViewController(searchTriggeringMode: .searchOnSubmit)
      
    case .searchAsYouType:
      viewController = SearchInputDemoViewController(searchTriggeringMode: .searchAsYouType)
      
    case .stats:
      viewController = StatsDemoViewController()
      
    case .highlighting:
      viewController = HighlightingDemoViewController()
      
    case .loading:
      viewController = LoadingDemoViewController()
      
    case .hierarchical:
      viewController = HierarchicalDemoViewController()
      
    case .querySuggestions:
      viewController = QuerySuggestionsDemoViewController()
      
    case .relatedItems:
      viewController = RelatedItemsDemoViewController()
      
    case .queryRuleCustomData:
      viewController = QueryRuleCustomDataDemoViewController()
      
    case .voiceSearch:
      viewController = VoiceInputDemoViewController()
    }
    
    viewController.title = demo.name
    
    return viewController
  }
  
}

extension DemoFactory {
  
  enum Error: Swift.Error {
    case demoNotImplemented
  }
  
}
