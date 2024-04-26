import Foundation

/// 整個 App 通用的東西。
enum AppUtility {}

// MARK: - formatter
extension AppUtility {
    /// 能回傳 API 需要的日期格式的 date formatter
    /// 整個專案的日期都必須使用這個格式！
    /// 因為會有伺服器接受的只有到日期，沒有到分秒，
    /// 所以如果使用 Date 的 instance 的話，會有誤差。
    static let requestDateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC") // server time zone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}
