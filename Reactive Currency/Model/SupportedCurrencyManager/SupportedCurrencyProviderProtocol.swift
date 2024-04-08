import Combine

protocol SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher() -> AnyPublisher<ResponseDataModel.SupportedSymbols, Error>
}
