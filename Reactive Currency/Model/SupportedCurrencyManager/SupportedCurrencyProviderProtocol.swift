import Combine

protocol SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher(id: String) -> AnyPublisher<ResponseDataModel.SupportedSymbols, Error>
}
