import Foundation
import Combine

class Fetcher: BaseFetcher {
    func publisher<Endpoint: EndpointProtocol>(
        for endpoint: Endpoint,
        id: String = UUID().uuidString // TODO: 全部的 endpoint 都有自己的 id 後，這個預設值要刪掉
    ) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        createRequestTupleFor(endpoint)
            .publisher
            .handleEvents(receiveCompletion: { [unowned self] completion in
                guard case .failure(let error) = completion else { return }
                logger.debug("\(endpoint) with id \(id) fails with error:\(error)")
            })
            .flatMap { [unowned self] (urlRequest: URLRequest, apiKey: String) in
                logger.debug("\(endpoint) with id \(id) starts requesting using api key: \(apiKey)")
                
                return currencySession.currencyDataTaskPublisher(for: urlRequest)
                    .mapError { $0 }
                    .flatMap { [unowned self] data, urlResponse in
                        venderResultFor(data: data, urlResponse: urlResponse)
                            .publisher
                            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
                            .handleEvents(receiveOutput: { [unowned self] _ in
                                logger.debug("\(endpoint) with id \(id) using api key: \(apiKey) finishes with data")
                            })
                            .tryCatch { [unowned self] error in
                                do { throw error }
                                catch Error.runOutOfQuota, Error.invalidAPIKey {
                                    logger.debug("\(endpoint) with id \(id) deprecates api key: \(apiKey)")
                                    deprecate(apiKey)
                                    
                                    return publisher(for: endpoint, id: id)
                                }
                                catch {
                                    logger.debug("\(endpoint) with id \(id) using api key: \(apiKey) fails with error:\(error)")
                                    throw error
                                }
                            }
                    }
            }
            .eraseToAnyPublisher()
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String, id: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Swift.Error> {
        publisher(for: Endpoints.Historical(dateString: dateString), id: id)
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func latestRatePublisher(id: String) -> AnyPublisher<ResponseDataModel.LatestRate, Swift.Error> {
        publisher(for: Endpoints.Latest())
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrencyPublisher() -> AnyPublisher<ResponseDataModel.SupportedSymbols, Swift.Error> {
        publisher(for: Endpoints.SupportedSymbols())
    }
}
