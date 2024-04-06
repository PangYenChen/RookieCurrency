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
                            if let httpURLResponse = urlResponse as? HTTPURLResponse {
                                if httpURLResponse.statusCode == 401 {
                                    // server 回應 status code 401，表示 api key 無效
                                    switch keyManager.getUsingAPIKeyAfterDeprecating(apiKey) {
                                        case .success:
                                            // 更新完 api key 後重新打 api
                                            return dataTaskPublisherWithLimitHandling(for: endpoint)
                                                .eraseToAnyPublisher()
                                        case .failure:
                                            // 沒有有效 api key 可用
                                            return Fail(error: Fetcher.Error.invalidAPIKey)
                                                .eraseToAnyPublisher()
                                    }
                                }
                                else if httpURLResponse.statusCode == 429 {
                                    // server 回應 status code 429，表示 api key 額度用完
                                    switch keyManager.getUsingAPIKeyAfterDeprecating(apiKey) {
                                        case .success:
                                            // 更新完 api key 後重新打 api
                                            return dataTaskPublisherWithLimitHandling(for: endpoint)
                                                .eraseToAnyPublisher()
                                        case .failure:
                                            // 已經沒有還有額度的 api key 可以用了
                                            return Fail(error: Fetcher.Error.runOutOfQuota)
                                                .eraseToAnyPublisher()
                                    }
                                }
                                else {
                                    // 這是一切都正常的情況，把 data 跟 response 往下傳
                                    return Just((data: data, response: urlResponse))
                                        .setFailureType(to: Swift.Error.self)
                                        .eraseToAnyPublisher()
                                }
                            }
                            else {
                                assertionFailure("###, \(#function), \(self), response 不是 HttpURLResponse，常理來說都不會發生。")
                                return Fail(error: Error.unknownError)
                                    .eraseToAnyPublisher()
                            }
                        }
                        .eraseToAnyPublisher()
                case .failure(let failure):
                    return Fail(error: Error.invalidAPIKey)
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
