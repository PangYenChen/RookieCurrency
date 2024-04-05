import Foundation

class Fetcher: BaseFetcher {
    /// 向服務商伺服器索取資料
    /// - Parameters:
    ///   - endpoint: The end point to be retrieved.
    ///   - completionHandler: The completion handler to call when the load request is complete.
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ) {
        switch keyManager.getUsingAPIKey() {
            case .success(let apiKey):
                let urlRequest: URLRequest = createRequest(url: endpoint.url, withAPIKey: apiKey)
                
                currencySession.rateDataTask(with: urlRequest) { [unowned self] data, response, error in
                    if let httpURLResponse = response as? HTTPURLResponse, let data {
                        if httpURLResponse.statusCode == 401 {
                            // status code 是 401 表示 api key 無效，要更新 api key 後重新打
                            switch keyManager.getUsingAPIKeyAfterDeprecating(apiKey) {
                                case .success:
                                    // 更新成功後重新打 api
                                    fetch(endpoint, completionHandler: completionHandler)
                                case .failure:
                                    // 沒有有效的 api key
                                    completionHandler(.failure(Error.invalidAPIKey))
                                    print("###, \(self), \(#function), api key 無效")
                            }
                        }
                        else if httpURLResponse.statusCode == 429 {
                            // status code 是 429 表示 api key 的額度已經用完，要更新 api key 後重新打
                            switch keyManager.getUsingAPIKeyAfterDeprecating(apiKey) {
                                case .success:
                                    // 更新成功後重新打 api
                                    fetch(endpoint, completionHandler: completionHandler)
                                case .failure(let failure):
                                    // 沒有還有額度的 api key
                                    completionHandler(.failure(Error.tooManyRequest))
                                    print("###, \(self), \(#function), api key 的額度用罄")
                            }
                        }
                        else {
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
                        }
                    }
                    else if let error {
                        // 網路錯誤，例如 timeout
                        completionHandler(.failure(error))
                        print("###", self, #function, "網路錯誤", error.localizedDescription, error)
                    }
                    else {
                        assertionFailure("###, \(#function), \(self), response 不是 HttpURLResponse，或者既沒有(data, httpURLResponse)，也沒有 error，常理來說都不會發生。")
                        completionHandler(.failure(Error.unknownError))
                    }
                }
            case .failure(let failure):
                completionHandler(.failure(failure))
        }
    }
}

extension Fetcher: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        fetch(Endpoints.Historical(dateString: dateString), completionHandler: resultHandler)
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func rate(resultHandler latestRateResultHandler: @escaping LatestRateResultHandler) {
        fetch(Endpoints.Latest(), completionHandler: latestRateResultHandler)
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrency(completionHandler: @escaping SupportedCurrencyHandler) {
        fetch(Endpoints.SupportedSymbols(), completionHandler: completionHandler)
    }
}
