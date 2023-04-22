//
//  AlertPresenter.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/22.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

protocol ErrorAlertPresenter {
    func presentErrorAlert(error: Error)
}

extension ErrorAlertPresenter where Self: UIViewController {
    func presentErrorAlert(error: Error) {
        
        let alertController: UIAlertController
        
        // alert controller
        do {
            let alertTitle = R.string.localizable.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: error.localizedDescription,
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
}
