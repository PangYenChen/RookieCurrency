import OSLog

enum LoggerFactory {}

extension LoggerFactory {
    static func make(category: String) -> Logger {
        Logger(subsystem: "Reactive Currency", category: category)
    }
}
