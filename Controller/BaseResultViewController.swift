//
//  BaseResultViewController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/7/22.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit

/// This class is designed to be subclassed.
class BaseResultViewController: UIViewController {
    // MARK: - Property
    @IBOutlet weak var numberOfDayTitle: UILabel!
    @IBOutlet weak var numberOfDayTextField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var latestUpdateTimeTitle: UILabel!
    @IBOutlet weak var latestUpdateTimeLabel: UILabel!
    @IBOutlet weak var baseCurrencyTitleLabel: UILabel!
    @IBOutlet weak var baseCurrencyLabel: UILabel!
    @IBOutlet weak var baseCurrencyChangingButton: UIButton!
    
    override func viewDidLoad() {
        
        localized()
    }
    // MARK: - methods
    private func localized() {
        numberOfDayTitle.text = R.string.localizable.numberOfConsideredDay()
        latestUpdateTimeTitle.text = R.string.localizable.latestUpdateTime()
        baseCurrencyTitleLabel.text = R.string.localizable.baseCurrency()
        baseCurrencyChangingButton.setTitle(R.string.localizable.changeBaseCurrency(),
                                            for: .normal)
    }
    
    @IBAction func stepperValueDidChange(_ sender: UIStepper) {
        fatalError("stepperValueDidChange(_:) has not been implemented")
    }
    
    @IBAction func chooseBaseCurrency(_ sender: UIButton) {
        fatalError(".chooseBaseCurrency(_:) has not been implemented")
    }
}
