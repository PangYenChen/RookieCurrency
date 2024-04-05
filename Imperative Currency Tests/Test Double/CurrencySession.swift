import Foundation

@testable import ImperativeCurrency

extension TestDouble {
    class CurrencySession: CurrencySessionProtocol {
        
        private var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        
        func rateDataTask(with request: URLRequest, 
                          completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func executeCompletionHandler(with data: Data?, _ urlResponse: URLResponse?, _ error: Error?) {
            completionHandler?(data, urlResponse, error)
            completionHandler = nil
        }
    }
}
