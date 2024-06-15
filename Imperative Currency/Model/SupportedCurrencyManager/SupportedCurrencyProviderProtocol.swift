protocol SupportedCurrencyProviderProtocol {
    func supportedCurrency(traceIdentifier: String, resultHandler: @escaping SupportedCurrencyResultHandler)
}

extension SupportedCurrencyProviderProtocol {
    typealias SupportedCurrencyResultHandler = (_ supportedCurrencyResult: Result<ResponseDataModel.SupportedSymbols, Error>) -> Void
}
