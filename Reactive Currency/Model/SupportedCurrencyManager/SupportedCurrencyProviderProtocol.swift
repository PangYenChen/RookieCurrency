import Combine

protocol SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher(traceIdentifier: String) -> AnyPublisher<ResponseDataModel.SupportedSymbols, Error>
}
