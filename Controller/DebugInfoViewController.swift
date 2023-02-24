//
//  DebugInfoViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/24.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class DebugInfoViewController: UIViewController {
#if DEBUG
    @IBOutlet weak var homeDirectoryTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeDirectoryTextView.text = NSHomeDirectory()
    }

#endif
}
