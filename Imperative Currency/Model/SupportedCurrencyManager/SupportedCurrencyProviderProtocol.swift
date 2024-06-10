protocol SupportedCurrencyProviderProtocol {
    func supportedCurrency(resultHandler: @escaping SupportedCurrencyResultHandler)
}

extension SupportedCurrencyProviderProtocol {
    typealias SupportedCurrencyResultHandler = (_ supportedCurrencyResult: Result<ResponseDataModel.SupportedSymbols, Error>) -> Void
}
