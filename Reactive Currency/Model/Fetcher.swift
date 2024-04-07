import Foundation
import Combine

class Fetcher: BaseFetcher {
    /// 像服務商的伺服器索取資料。
    /// - Parameter endPoint: The end point to be retrieved.
    /// - Returns: The publisher publishes decoded instance when the task completes, or terminates if the task fails with an error.
    func publisher<Endpoint: EndpointProtocol>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        func dataTaskPublisherWithLimitHandling(for endpoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), Swift.Error> {
            switch keyManager.getUsingAPIKey() {
                case .success(let apiKey):
                    return currencySession.rateDataTaskPublisher(for: createRequest(url: endpoint.url, withAPIKey: apiKey))
                        .mapError { $0 }
                        .flatMap { [unowned self] data, urlResponse -> AnyPublisher<(data: Data, response: URLResponse), Swift.Error> in
                            switch venderResultFor(data: data, urlResponse: urlResponse) {
                                case .success:
                                    // 這是一切都正常的情況，把 data 跟 response 往下傳
                                    return Just((data: data, response: urlResponse))
                                        .setFailureType(to: Swift.Error.self)
                                        .eraseToAnyPublisher()
                                case .failure(let error):
                                    switch error {
                                        case .invalidAPIKey, .runOutOfQuota:
                                            switch keyManager.getUsingAPIKeyAfterDeprecating(apiKey) {
                                                case .success:
                                                    // 更新完 api key 後重新打 api
                                                    return dataTaskPublisherWithLimitHandling(for: endpoint)
                                                        .eraseToAnyPublisher()
                                                case .failure:
                                                    // 沒有 api key 可用了
                                                    return Fail(error: error)
                                                        .eraseToAnyPublisher()
                                            }
                                        case .unknownError:
                                            assertionFailure("###, \(#function), \(self), response 不是 HttpURLResponse，常理來說都不會發生。")
                                            return Fail(error: Error.unknownError)
                                                .eraseToAnyPublisher()
                                    }
                            }
                        }
                        .eraseToAnyPublisher()
                case .failure(let failure):
                    return Fail(error: failure)
                        .eraseToAnyPublisher()
            }
        }
        
        return dataTaskPublisherWithLimitHandling(for: endpoint)
            .map { $0.0 }
            .handleEvents(receiveOutput: AppUtility.prettyPrint)
            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Swift.Error> {
        publisher(for: Endpoints.Historical(dateString: dateString))
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func publisher() -> AnyPublisher<ResponseDataModel.LatestRate, Swift.Error> {
        publisher(for: Endpoints.Latest())
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrency() -> AnyPublisher<ResponseDataModel.SupportedSymbols, Swift.Error> {
        publisher(for: Endpoints.SupportedSymbols())
    }
}
