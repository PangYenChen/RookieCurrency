import OSLog

enum LoggerFactory {}

extension LoggerFactory {
    static func make(category: String) -> Logger {
        Logger(subsystem: "Imperative Currency", category: category)
    }
}
