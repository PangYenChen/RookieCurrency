//
//  AlertPresenter.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/22.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

protocol AlertPresenter {
    func presentAlert(error: Error)
    func presentAlert(message: String)
}

extension AlertPresenter where Self: UIViewController {
    
    func presentAlert(message: String) {
        let alertController: UIAlertController
        
        // alert controller
        do {
            let alertTitle = R.string.localizable.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        }
        
        // alert action
        do {
            let alertActionTitle = R.string.localizable.alertActionTitle()
            let alertAction = UIAlertAction(title: alertActionTitle, style: .cancel)
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true)
    }
    
    func presentAlert(error: Error) {
        presentAlert(message: error.localizedDescription)
    }
}
