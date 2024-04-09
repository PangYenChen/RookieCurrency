import Foundation

class Fetcher: BaseFetcher {
    /// 向服務商伺服器索取資料
    /// - Parameters:
    ///   - endpoint: The end point to be retrieved.
    ///   - completionHandler: The completion handler to call when the load request is complete.
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping CompletionHandler<Endpoint.ResponseType>
    ) {
        let usingAPIKeyResult: Result<String, Swift.Error> = threadSafeKeyManager
            .readSynchronously { keyManager in keyManager.usingAPIKeyResult }
        
        switch usingAPIKeyResult {
            case .success(let apiKey):
                let urlRequest: URLRequest = createRequest(url: endpoint.url, withAPIKey: apiKey)
                
                currencySession.currencyDataTask(with: urlRequest) { [unowned self] data, urlResponse, error in
                    if let data, let urlResponse {
                        switch venderResultFor(data: data, urlResponse: urlResponse) {
                            case .success(let data):
                                AppUtility.prettyPrint(data)
                                // 正常的情況，將 data decode，或者有其他未知的錯誤
                                do {
                                    let rate: Endpoint.ResponseType = try jsonDecoder.decode(Endpoint.ResponseType.self, from: data)
                                    completionHandler(.success(rate))
                                }
                                catch {
                                    completionHandler(.failure(error))
                                    print("###, \(self), \(#function), decode 失敗, \(error.localizedDescription), \(error)")
                                }
                            case .failure(let error):
                                switch error {
                                    case .runOutOfQuota, .invalidAPIKey:
                                        threadSafeKeyManager.writeAsynchronously { keyManager in
                                            keyManager.deprecate(apiKey)
                                            return keyManager
                                        }
                                        
                                        let usingAPIKeyResult: Result<String, Swift.Error> = threadSafeKeyManager
                                            .readSynchronously { keyManager in keyManager.usingAPIKeyResult }
                                        
                                        switch usingAPIKeyResult {
                                            case .success:
                                                // 更新成功後重新打 api
                                                fetch(endpoint, completionHandler: completionHandler)
                                            case .failure:
                                                // 沒有 api key 了
                                                completionHandler(.failure(error))
                                        }
                                        
                                    case .unknownError:
                                        assertionFailure("###, \(#function), \(self), response 不是 HttpURLResponse，常理來說不會發生。")
                                        completionHandler(.failure(Error.unknownError))
                                }
                        }
                    }
                    else if let error {
                        // 網路錯誤，例如 timeout
                        completionHandler(.failure(error))
                        print("###", self, #function, "網路錯誤", error.localizedDescription, error)
                    }
                    else {
                        assertionFailure("###, \(#function), \(self), 既沒有(data, httpURLResponse)，也沒有 error，常理來說不會發生。")
                        completionHandler(.failure(Error.unknownError))
                    }
                }
            case .failure(let failure):
                completionHandler(.failure(failure))
        }
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        fetch(Endpoints.Historical(dateString: dateString), completionHandler: resultHandler)
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func latestRate(resultHandler latestRateResultHandler: @escaping LatestRateResultHandler) {
        fetch(Endpoints.Latest(), completionHandler: latestRateResultHandler)
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrency(completionHandler: @escaping SupportedCurrencyHandler) {
        fetch(Endpoints.SupportedSymbols(), completionHandler: completionHandler)
    }
}

extension Fetcher {
    typealias CompletionHandler<ResponseType> = (_ result: Result<ResponseType, Swift.Error>) -> Void
}
