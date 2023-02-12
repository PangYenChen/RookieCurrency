//
//  SettingNavigationController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingNavigationController: UINavigationController {
    
    private let resultTableViewController: ResultTableViewController
    
    init?(coder aDecoder: NSCoder, resultTableViewController: ResultTableViewController) {
        self.resultTableViewController = resultTableViewController
        
        super.init(coder: aDecoder)
        
        if let settingTableViewController = viewControllers.first as? SettingTableViewController {
            settingTableViewController.resultTableViewController = resultTableViewController
        }
        
        print("###, \(#function), \(self), ")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()


    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("###, \(#function), \(self)")
//    }
    
//    @IBSegueAction func embedSetting(_ coder: NSCoder) -> SettingTableViewController? {
//        return SettingTableViewController(coder: coder, resultTableViewController: resultTableViewController)
//    }
}
