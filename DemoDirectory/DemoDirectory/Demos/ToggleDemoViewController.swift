//
//  ToggleDemoViewController.swift
//  development-pods-instantsearch
//
//  Created by Vladislav Fitc on 03/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit
import InstantSearch

class ToggleDemoViewController: UIViewController {
  
  let searcher: SingleIndexSearcher
  let filterState: FilterState
  let searchStateViewController: SearchStateViewController
  
  let sizeConstraintConnector: FilterToggleConnector<Filter.Numeric>
  let vintageConnector: FilterToggleConnector<Filter.Tag>
  let couponConnector: FilterToggleConnector<Filter.Facet>
  
  let mainStackView = UIStackView()
  let controlsStackView = UIStackView()
  let couponStackView = UIStackView()
  
  let vintageButtonController: SelectableFilterButtonController<Filter.Tag>
  let sizeConstraintButtonController: SelectableFilterButtonController<Filter.Numeric>
  let couponSwitchController: FilterSwitchController<Filter.Facet>
  
  let couponLabel = UILabel()
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    
    searcher = SingleIndexSearcher(client: .demo, indexName: "mobile_demo_filter_toggle")
    filterState = .init()
    searchStateViewController = SearchStateViewController()
    
    // Size constraint button
    let sizeConstraintFilter = Filter.Numeric(attribute: "size", operator: .greaterThan, value: 40)
    sizeConstraintButtonController = SelectableFilterButtonController(button: .init())
    sizeConstraintConnector = .init(filterState: filterState, filter: sizeConstraintFilter, controller: sizeConstraintButtonController)
    
    // Vintage tag button
    let vintageFilter = Filter.Tag(value: "vintage")
    vintageButtonController = SelectableFilterButtonController(button: .init())
    vintageConnector = .init(filterState: filterState, filter: vintageFilter, controller: vintageButtonController)
    
    // Coupon switch
    let couponFacet = Filter.Facet(attribute: "promotions", stringValue: "coupon")
    couponSwitchController = FilterSwitchController(switch: .init())
    couponConnector = .init(filterState: filterState, filter: couponFacet, controller: couponSwitchController)
    
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
    setup()

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
}


private extension ToggleDemoViewController {
  
  func setup() {
    searcher.connectFilterState(filterState)
    searchStateViewController.connectSearcher(searcher)
    searchStateViewController.connectFilterState(filterState)
    searcher.search()    
  }
  
  func setupUI() {
    view.backgroundColor = .white
    configureSizeButton()
    configureVintageButton()
    configureCouponLabel()
    configureCouponSwitch()
    configureCouponStackView()
    configureMainStackView()
    configureControlsStackView()
    configureLayout()
  }
  
  func configureLayout() {
    
    view.addSubview(mainStackView)
    
    mainStackView.pin(to: view.safeAreaLayoutGuide)
    
    addChild(searchStateViewController)

    searchStateViewController.didMove(toParent: self)
    mainStackView.addArrangedSubview(searchStateViewController.view)
    
    NSLayoutConstraint.activate([
      searchStateViewController.view.heightAnchor.constraint(equalToConstant: 150),
      searchStateViewController.view.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.98)
    ])
    
    sizeConstraintButtonController.button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    vintageButtonController.button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    couponStackView.addArrangedSubview(couponLabel)
    couponStackView.addArrangedSubview(couponSwitchController.switch)
    couponStackView.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    controlsStackView.addArrangedSubview(spacer())
    controlsStackView.addArrangedSubview(sizeConstraintButtonController.button)
    controlsStackView.addArrangedSubview(spacer())
    controlsStackView.addArrangedSubview(vintageButtonController.button)
    controlsStackView.addArrangedSubview(spacer())
    controlsStackView.addArrangedSubview(couponStackView)
    controlsStackView.addArrangedSubview(spacer())
    mainStackView.addArrangedSubview(controlsStackView)
    mainStackView.addArrangedSubview(spacer())
    controlsStackView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 1).isActive = true
  }
  
  private func spacer() -> UIView {
    let view = UIView()
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    return view
  }
  
  func configureMainStackView() {
    mainStackView.axis = .vertical
    mainStackView.alignment = .center
    mainStackView.spacing = .px16
    mainStackView.distribution = .fill
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
  }
  
  func configureControlsStackView() {
    controlsStackView.axis = .horizontal
    controlsStackView.distribution = .equalSpacing
    controlsStackView.translatesAutoresizingMaskIntoConstraints = false
  }
  
  func configureCouponStackView() {
    couponStackView.translatesAutoresizingMaskIntoConstraints = false
    couponStackView.axis = .horizontal
    couponStackView.spacing = .px16
    couponStackView.alignment = .center
    couponStackView.distribution = .fill
  }
    
  func configureSizeButton() {
    let button = sizeConstraintButtonController.button
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("size > 40", for: .normal)
    button.setTitleColor(.black, for: .normal)
    button.setTitleColor(.systemGreen, for: .selected)
    button.layer.borderWidth = 1
    button.layer.cornerRadius = 10
    button.contentEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
    button.addTarget(self, action: #selector(didTapSizeButton), for: .touchUpInside)
  }
  
  @objc func didTapSizeButton(_ button: UIButton) {
    let borderColor: UIColor =  button.isSelected ? .black : .systemGreen
    button.layer.borderColor = borderColor.cgColor
  }
  
  func configureVintageButton() {
    let button = vintageButtonController.button
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("vintage", for: .normal)
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
    button.setTitleColor(.black, for: .normal)
    button.setImage(UIImage(named: "square"), for: .normal)
    button.setImage(UIImage(named: "check-square"), for: .selected)
  }
  
  func configureCouponSwitch() {
    couponSwitchController.switch.translatesAutoresizingMaskIntoConstraints = false
  }
  
  func configureCouponLabel() {
    couponLabel.text = "Coupon"
    couponLabel.translatesAutoresizingMaskIntoConstraints = false
  }
  
}
