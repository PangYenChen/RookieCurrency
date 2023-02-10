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
    
    var resultTableViewController: ResultTableViewController!
    
    // MARK: - methods
    override func viewDidLoad() {
        setUpFontAndLocalize()
    }
    
    private func setUpFontAndLocalize() {
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("-")
        numberOfDayLabel.adjustsFontForContentSizeCategory = true
        numberOfDayLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        latestUpdateTimeLabel.text = R.string.localizable.latestUpdateTime("-")
        latestUpdateTimeLabel.adjustsFontForContentSizeCategory = true
        latestUpdateTimeLabel.font = UIFont.preferredFont(forTextStyle: .body)
                                                     
        baseCurrencyLabel.text = R.string.localizable.baseCurrency("-")
        baseCurrencyLabel.adjustsFontForContentSizeCategory = true
        baseCurrencyLabel.font = UIFont.preferredFont(forTextStyle: .body)
                                                     
        baseCurrencyChangingButton.setTitle(R.string.localizable.changeBaseCurrency(),
                                            for: .normal)
        baseCurrencyChangingButton.titleLabel?.adjustsFontForContentSizeCategory = true
        baseCurrencyChangingButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    @IBAction func stepperValueDidChange(_ sender: UIStepper) {
        assertionFailure("stepperValueDidChange(_:) has not been implemented")
    }
    
    @IBAction func chooseBaseCurrency(_ sender: UIButton) {
        assertionFailure(".chooseBaseCurrency(_:) has not been implemented")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let identifier = R.segue.resultViewController.embedResultTableViewController.identifier
        
        if segue.identifier == identifier,
           let resultTableViewController = segue.destination as? ResultTableViewController {
            self.resultTableViewController = resultTableViewController
        }
    }
}
