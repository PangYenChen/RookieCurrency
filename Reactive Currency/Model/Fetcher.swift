import Foundation
import Combine

class Fetcher: BaseFetcher {
    func publisher<Endpoint: EndpointProtocol>(
        for endpoint: Endpoint,
        traceIdentifier: String
    ) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        createRequestTupleFor(endpoint)
            .publisher
            .handleEvents(
                receiveOutput: { [weak self] urlRequestAndAPIKey in
                    let apiKey: String = urlRequestAndAPIKey.apiKey
                    self?.logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), starts requesting, api key: \(apiKey)")
                },
                receiveCompletion: { [unowned self] completion in
                    guard case .failure(let error) = completion else { return }
                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), fails with error:\(error)")
                }
            )
            .flatMap { [unowned self] (urlRequest: URLRequest, apiKey: String) in
                currencySession.currencyDataTaskPublisher(for: urlRequest)
                    .mapError { $0 }
                    .flatMap { [unowned self] data, urlResponse in
                        venderResultFor(data: data, urlResponse: urlResponse)
                            .publisher
                            .handleEvents(receiveOutput: { [weak self] _ in
                                self?.logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), receive data, api key: \(apiKey)")
                            })
                            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
                            .tryCatch { [unowned self] error in
                                do { throw error }
                                catch Error.runOutOfQuota, Error.invalidAPIKey {
                                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), deprecates api key: \(apiKey)")
                                    deprecate(apiKey)
                                    
                                    return publisher(for: endpoint, traceIdentifier: traceIdentifier)
                                }
                                catch {
                                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), fails with error:\(error), api key: \(apiKey)")
                                    throw error
                                }
                            }
                    }
            }
            .eraseToAnyPublisher()
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String, traceIdentifier: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Swift.Error> {
        publisher(for: Endpoints.Historical(dateString: dateString), traceIdentifier: traceIdentifier)
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func latestRatePublisher(traceIdentifier: String) -> AnyPublisher<ResponseDataModel.LatestRate, Swift.Error> {
        publisher(for: Endpoints.Latest(), traceIdentifier: traceIdentifier)
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher(traceIdentifier: String) -> AnyPublisher<ResponseDataModel.SupportedSymbols, Swift.Error> {
        publisher(for: Endpoints.SupportedSymbols(), traceIdentifier: traceIdentifier)
    }
}
