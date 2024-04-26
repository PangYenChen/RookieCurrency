import Foundation
import Combine

class Fetcher: BaseFetcher {
    func publisher<Endpoint: EndpointProtocol>(
        for endpoint: Endpoint,
        id: String = UUID().uuidString
    ) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        
        createRequestTupleFor(endpoint)
            .publisher
            .flatMap { [unowned self] (urlRequest: URLRequest, apiKey: String) in
                currencySession.currencyDataTaskPublisher(for: urlRequest)
                    .mapError { $0 }
                    .flatMap { [unowned self] data, urlResponse in
                        venderResultFor(data: data, urlResponse: urlResponse)
                            .publisher
                            .handleEvents(receiveOutput: AppUtility.prettyPrint)
                            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
                            .tryCatch { [unowned self] error in
                                do { throw error }
                                catch Error.runOutOfQuota, Error.invalidAPIKey {
                                    deprecate(apiKey)
                                    
                                    return publisher(for: endpoint, id: id)
                                }
                                catch { throw error }
                            }
                    }
            }
            .eraseToAnyPublisher()
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Swift.Error> {
        publisher(for: Endpoints.Historical(dateString: dateString))
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func latestRatePublisher() -> AnyPublisher<ResponseDataModel.LatestRate, Swift.Error> {
        publisher(for: Endpoints.Latest())
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher() -> AnyPublisher<ResponseDataModel.SupportedSymbols, Swift.Error> {
        publisher(for: Endpoints.SupportedSymbols())
    }
}
