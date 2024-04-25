import Foundation

class Fetcher: BaseFetcher {
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        id: String = UUID().uuidString,
        completionHandler: @escaping CompletionHandler<Endpoint.ResponseType>
    ) {
        do {
            let (urlRequest, apiKey): (URLRequest, String) = try createRequestTupleFor(endpoint)
                .get()
            
            currencySession.currencyDataTask(with: urlRequest) { [unowned self] data, urlResponse, error in
                do {
                    let data: Data = try venderResultFor(data: data, urlResponse: urlResponse, error: error)
                        .get()
                    
                    AppUtility.prettyPrint(data)
                    // 正常的情況，將 data decode，或者有其他未知的錯誤
                    completionHandler(Result { try jsonDecoder.decode(Endpoint.ResponseType.self, from: data) })
                }
                catch Error.invalidAPIKey, Error.runOutOfQuota {
                    threadSafeKeyManager.writeAsynchronously { keyManager in
                        keyManager.deprecate(apiKey)
                        return keyManager
                    }
                    
                    fetch(endpoint, id: id, completionHandler: completionHandler)
                }
                catch {
                    completionHandler(.failure(error))
                }
            }
        }
        catch {
            completionHandler(.failure(error))
        }
    }
    
    func createRequestTupleFor(
        _ endpoint: any EndpointProtocol
    ) -> Result<(urlRequest: URLRequest, apiKey: String), Swift.Error> {
        endpoint.urlResult.flatMap { url in
            threadSafeKeyManager.readSynchronously { keyManager in keyManager.usingAPIKeyResult }
                .map { apiKey in
                    let timeoutInterval: TimeInterval = 5
                    var urlRequest: URLRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
                    urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
                    return (urlRequest, apiKey)
                }
        }
    }
}

private extension Fetcher {
    func venderResultFor(data: Data?, urlResponse: URLResponse?, error: Swift.Error?) -> Result<Data, Swift.Error> {
        if let data, let urlResponse {
            return venderResultFor(data: data, urlResponse: urlResponse)
                .mapError { $0 }
        }
        else if let error /*網路錯誤，例如 timeout*/ {
            return .failure(error)
        }
        else {
            assertionFailure("###, \(#function), \(self), 既沒有(data, urlResponse)，也沒有 error，常理來說不會發生。")
            return .failure(Error.unknownError)
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
