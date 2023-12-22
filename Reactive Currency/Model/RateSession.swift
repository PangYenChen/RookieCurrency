import Foundation
import Combine

// MARK: - RateSession
protocol RateSession {
    /// 把 URLSession 包一層起來，在測試的時候換掉。
    /// - Parameter request: The URL request for which to create a data task.
    /// - Returns: The publisher publishes data when the task completes, or terminates if the task fails with an error.
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// MARK: - make url session confirm RateSession
extension URLSession: RateSession {
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}
