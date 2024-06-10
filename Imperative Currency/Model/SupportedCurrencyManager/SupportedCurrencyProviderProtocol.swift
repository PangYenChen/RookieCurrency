protocol SupportedCurrencyProviderProtocol {
    func supportedCurrency(id: String, resultHandler: @escaping SupportedCurrencyResultHandler)
}

extension SupportedCurrencyProviderProtocol {
    typealias SupportedCurrencyResultHandler = (_ supportedCurrencyResult: Result<ResponseDataModel.SupportedSymbols, Error>) -> Void
}
