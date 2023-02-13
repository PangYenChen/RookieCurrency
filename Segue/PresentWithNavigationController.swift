//
//  PresentWithNavigationController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/13.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class PresentWithNavigationController: UIStoryboardSegue {
    override func perform() {
        let navigationController = UINavigationController(rootViewController: destination)
        source.present(navigationController, animated: true)
        
        navigationController.presentationController?.delegate = destination as? UIAdaptivePresentationControllerDelegate
    }
}
