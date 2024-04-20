import Foundation
import Combine

class Fetcher: BaseFetcher {
    /// 像服務商的伺服器索取資料。
    /// - Parameter endPoint: The end point to be retrieved.
    /// - Returns: The publisher publishes decoded instance when the task completes, or terminates if the task fails with an error.
    func publisher<Endpoint: EndpointProtocol>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        func dataTaskPublisherWithLimitHandling(for endpoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), Swift.Error> {
            let apiKey: String
            do {
                apiKey = try threadSafeKeyManager
                    .readSynchronously { keyManager in keyManager.usingAPIKeyResult }
                    .get()
            }
            catch {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            
            let urlRequest: URLRequest
            do {
                urlRequest = try endpoint.urlResult
                    .map { url in createRequest(url: url, withAPIKey: apiKey) }
                    .get()
            }
            catch {
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            
            return currencySession.currencyDataTaskPublisher(for: urlRequest)
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
                                    threadSafeKeyManager.writeAsynchronously { keyManager in
                                        keyManager.deprecate(apiKey)
                                        return keyManager
                                    }
                                    
                                    let usingAPIKeyResult: Result<String, Swift.Error> = threadSafeKeyManager
                                        .readSynchronously { keyManager in keyManager.usingAPIKeyResult }
                                    
                                    switch usingAPIKeyResult {
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
        }
        
        return dataTaskPublisherWithLimitHandling(for: endpoint)
            .map { $0.0 }
            .handleEvents(receiveOutput: AppUtility.prettyPrint)
            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
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
