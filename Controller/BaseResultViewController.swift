//
//  BaseResultViewController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/7/22.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit

/// An abstract base class for view controller displaying result.
/// This class is designed to be subclassed.
class BaseResultViewController: UIViewController {
    // MARK: - Property
    @IBOutlet weak var numberOfDayLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var latestUpdateTimeLabel: UILabel!
    @IBOutlet weak var baseCurrencyLabel: UILabel!
    @IBOutlet weak var baseCurrencyChangingButton: UIButton!
    
    override func viewDidLoad() {
        
        localized()
    }
    // MARK: - methods
    private func localized() {
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("-")
        latestUpdateTimeLabel.text = R.string.localizable.latestUpdateTime("-")
        baseCurrencyLabel.text = R.string.localizable.baseCurrency("-")
        baseCurrencyChangingButton.setTitle(R.string.localizable.changeBaseCurrency(),
                                            for: .normal)
    }
    
    @IBAction func stepperValueDidChange(_ sender: UIStepper) {
        assertionFailure("stepperValueDidChange(_:) has not been implemented")
    }
    
    @IBAction func chooseBaseCurrency(_ sender: UIButton) {
        assertionFailure(".chooseBaseCurrency(_:) has not been implemented")
    }
}
