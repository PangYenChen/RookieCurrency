@testable import ImperativeCurrency

extension TestDouble {
    class SupportedCurrencyProvider: SupportedCurrencyProviderProtocol {
        init() {
            completionHandler = nil
            numberOfFunctionCall = 0
        }
        
        private var completionHandler: SupportedCurrencyHandler?
        
        private(set) var numberOfFunctionCall: Int
        
        func supportedCurrency(completionHandler: @escaping SupportedCurrencyHandler) {
            self.completionHandler = completionHandler
            numberOfFunctionCall += 1
        }
        
        func executeCompletionHandler(with result: Result<ResponseDataModel.SupportedSymbols, Error>) {
            completionHandler?(result)
            completionHandler = nil
        }
    }
}
