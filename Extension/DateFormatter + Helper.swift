//
//  DateFormatter + Helper.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

extension DateFormatter {
    /// 能回傳 API 需要的日期格式的 date formatter
    /// 整個專案的日期都必須使用這個格式！
    /// 因為會有伺服器接受的只有到日期，沒有到分秒，
    /// 所以如果使用 Date 的 instance 的話，會有誤差。
    static let requestDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        // 好像不需要 Gregorian calendar 的樣子
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    /// 畫面上顯示的日期格式的 date formatter
    static let uiDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
}
