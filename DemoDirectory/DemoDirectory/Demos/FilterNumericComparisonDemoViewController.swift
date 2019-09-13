//
//  FilterNumericComparisonDemoViewController.swift
//  development-pods-instantsearch
//
//  Created by Guy Daher on 05/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit
import InstantSearch

class FilterNumericComparisonDemoViewController: UIViewController {

  let yearAttribute = Attribute("year")
  let priceAttribute = Attribute("price")

  let searcher: SingleIndexSearcher
  let filterState: FilterState

  let numberInteractor: NumberInteractor<Int>
  let numberInteractor2: NumberInteractor<Int>
  let numberInteractor3: NumberInteractor<Double>

  let searchStateViewController: SearchStateViewController

  let numericTextFieldController1: TextFieldController
  let numericTextFieldController2: NumericTextFieldController
  let numericStepperController: NumericStepperController

  let mainStackView = UIStackView(frame: .zero)
  let stepperStackView = UIStackView(frame: .zero)
  let stepperLabel = UILabel()

  let textField = UITextField()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.searcher = SingleIndexSearcher(index: .demo(withName:"mobile_demo_filter_numeric_comparison"))
    self.filterState = .init()
    numberInteractor = .init()
    numberInteractor2 = .init()
    numberInteractor3 = .init()
  
    let stepper = UIStepper()

    let textField2 = UITextField()
    textField2.keyboardType = .numberPad

    numericTextFieldController1 = TextFieldController(textField: textField)
    numericTextFieldController2 = NumericTextFieldController(textField: textField2)
    numericStepperController = NumericStepperController(stepper: stepper)

    self.searchStateViewController = SearchStateViewController()
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


private extension FilterNumericComparisonDemoViewController {

  func setup() {
    
    searcher.connectFilterState(filterState)
    
    numberInteractor.connectFilterState(filterState, attribute: yearAttribute, numericOperator: .greaterThanOrEqual)
    //numberInteractor.connectController(numericTextFieldController1)
    numberInteractor.connectSearcher(searcher, attribute: yearAttribute)

    numberInteractor2.connectFilterState(filterState, attribute: yearAttribute, numericOperator: .greaterThanOrEqual)
    numberInteractor2.connectController(numericTextFieldController2)
    numberInteractor2.connectSearcher(searcher, attribute: yearAttribute)

    numberInteractor3.connectFilterState(filterState, attribute: priceAttribute, numericOperator: .greaterThanOrEqual)
    numberInteractor3.connectController(numericStepperController)
    numberInteractor3.connectSearcher(searcher, attribute: priceAttribute)

    searchStateViewController.connectSearcher(searcher)
    searchStateViewController.connectFilterState(filterState)

    searcher.search()
  }

  func setupUI() {
    view.backgroundColor = .white
    configureMainStackView()

    addChild(searchStateViewController)
    searchStateViewController.didMove(toParent: self)
    searchStateViewController.view.heightAnchor.constraint(equalToConstant: 150).isActive = true

    mainStackView.addArrangedSubview(searchStateViewController.view)
    searchStateViewController.view.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 1).isActive = true

    textField.layer.borderWidth = 1
    textField.layer.borderColor = UIColor.gray.cgColor
    textField.heightAnchor.constraint(equalToConstant: 40).isActive = true

    mainStackView.addArrangedSubview(textField)

    textField.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.4).isActive = true

    numericTextFieldController2.textField.layer.borderWidth = 1
    numericTextFieldController2.textField.layer.borderColor = UIColor.gray.cgColor
    numericTextFieldController2.textField.heightAnchor.constraint(equalToConstant: 40).isActive = true

    mainStackView.addArrangedSubview(numericTextFieldController2.textField)

    numericTextFieldController2.textField.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.4).isActive = true

    stepperStackView.addArrangedSubview(numericStepperController.stepper)
    stepperStackView.addArrangedSubview(stepperLabel)
    numericStepperController.stepper.addTarget(self, action: #selector(onStepperValueChanged), for: .valueChanged)
    mainStackView.addArrangedSubview(stepperStackView)

    let spacerView = UIView()
    spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    mainStackView.addArrangedSubview(spacerView)

    view.addSubview(mainStackView)

    mainStackView.pin(to: view.safeAreaLayoutGuide)
  }

  @objc func onStepperValueChanged(sender: UIStepper) {
    stepperLabel.text = "\(sender.value)"
  }

  func configureMainStackView() {
    mainStackView.axis = .vertical
    mainStackView.spacing = .px16
    mainStackView.distribution = .fill
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    mainStackView.alignment = .center
  }

  func configureStepperStackView() {
    stepperStackView.axis = .horizontal
    stepperStackView.spacing = .px16
    stepperStackView.distribution = .fill
    stepperStackView.translatesAutoresizingMaskIntoConstraints = false
    stepperStackView.alignment = .center
  }

}
