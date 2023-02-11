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
    
    // MARK: - Methods
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
    
    @IBAction func chooseBaseCurrency(_ sender: UIButton) {
        let alertTitle = R.string.localizable.pleaseChooseBaseCurrency()
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        
        for currency in ResponseDataModel.RateList.Currency.allCases {
            let alertAction = UIAlertAction(title: currency.name, style: .default) { [unowned self] (_) in
                didChooseBaseCurrency(currency)
            }
            
            alertController.addAction(alertAction)
        }
        
        let cancelTitle = R.string.localizable.cancel()
        let cancelAlertAction = UIAlertAction(title: cancelTitle, style: .cancel) { (_) in
            self.dismiss(animated: true)
        }
        
        alertController.addAction(cancelAlertAction)
        
        present(alertController, animated: true)
    }
    
    func didChooseBaseCurrency(_ currency: Currency) {
        assertionFailure("didChooseBaseCurrency(_:) has not been implemented.")
    }
}
