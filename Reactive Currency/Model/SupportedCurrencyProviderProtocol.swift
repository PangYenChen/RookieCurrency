import Combine

protocol SupportedCurrencyProviderProtocol {
    func supportedCurrency() -> AnyPublisher<ResponseDataModel.SupportedSymbols, Error>
}
