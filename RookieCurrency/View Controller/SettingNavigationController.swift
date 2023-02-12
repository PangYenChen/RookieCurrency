//
//  SettingNavigationController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingNavigationController: UINavigationController {
    
    init?(coder aDecoder: NSCoder, resultTableViewController: ResultTableViewController) {
        
        super.init(coder: aDecoder)
        
        if let settingTableViewController = viewControllers.first as? SettingTableViewController {
            settingTableViewController.resultTableViewController = resultTableViewController
            presentationController?.delegate = settingTableViewController
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
