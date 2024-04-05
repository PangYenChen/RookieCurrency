protocol SupportedCurrencyProviderProtocol {
    func supportedCurrency(completionHandler: @escaping SupportedCurrencyHandler)
}

extension SupportedCurrencyProviderProtocol {
    typealias SupportedCurrencyHandler = (_ supportedCurrencyResult: Result<ResponseDataModel.SupportedSymbols, Error>) -> Void
}
