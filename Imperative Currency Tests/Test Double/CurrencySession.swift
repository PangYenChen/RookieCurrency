import Foundation

@testable import ImperativeCurrency

extension TestDouble {
    class CurrencySession: CurrencySessionProtocol {
        init() {
            completionHandlers = []
        }
        
        private var completionHandlers: [(Data?, URLResponse?, Error?) -> Void]
        
        func currencyDataTask(with request: URLRequest,
                              completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) {
            completionHandlers.append(completionHandler)
        }
        
        func executeCompletionHandler(with data: Data?, _ urlResponse: URLResponse?, _ error: Error?) {
            guard !completionHandlers.isEmpty else { return }
            completionHandlers.removeFirst()(data, urlResponse, error)
        }
    }
}
