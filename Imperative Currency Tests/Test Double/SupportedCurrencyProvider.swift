@testable import ImperativeCurrency

extension TestDouble {
    class SupportedCurrencyProvider: SupportedCurrencyProviderProtocol {
        init() {
            completionHandler = nil
            numberOfFunctionCall = 0
        }
        
        private var completionHandler: SupportedCurrencyResultHandler?
        
        private(set) var numberOfFunctionCall: Int
        
        func supportedCurrency(traceIdentifier: String, resultHandler: @escaping SupportedCurrencyResultHandler) {
            self.completionHandler = resultHandler
            numberOfFunctionCall += 1
        }
        
        func executeCompletionHandler(with result: Result<ResponseDataModel.SupportedSymbols, Error>) {
            completionHandler?(result)
            completionHandler = nil
        }
    }
}
