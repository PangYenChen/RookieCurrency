//
//  UserDefaults + Helper.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/13.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    static var numberOfDay: Int {
        get {
            let numberOfDayInUserDefaults = UserDefaults.standard.integer(forKey: "numberOfDay")
            return numberOfDayInUserDefaults > 0 ? numberOfDayInUserDefaults : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: "numberOfDay") }
    }
    
    static var baseCurrency: Currency {
        get {
            if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
               let baseCurrency = Currency(rawValue: baseCurrencyString) {
                return baseCurrency
            } else {
                return .TWD
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "baseCurrency")
        }
    }
    
    static var order: ResultTableViewController.Order {
        get {
            if let orderString = UserDefaults.standard.string(forKey: "order"),
               let order = ResultTableViewController.Order(rawValue: orderString) {
                return order
            } else {
                return .increasing
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "order")
        }
    }
}
