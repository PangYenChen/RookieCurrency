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
            
            logger.debug("\(endpoint) with id \(id) starts requesting using api key: \(apiKey)")
            
            currencySession.currencyDataTask(with: urlRequest) { [unowned self] data, urlResponse, error in
                do {
                    let data: Data = try venderResultFor(data: data, urlResponse: urlResponse, error: error)
                        .get()
                    
                    AppUtility.prettyPrint(data)
                    // 正常的情況，將 data decode，或者有其他未知的錯誤
                    completionHandler(Result { try jsonDecoder.decode(Endpoint.ResponseType.self, from: data) })
                    logger.debug("\(endpoint) with id \(id) using api key: \(apiKey) finishes with data")
                }
                catch Error.invalidAPIKey, Error.runOutOfQuota {
                    logger.debug("\(endpoint) with id \(id) deprecates api key: \(apiKey)")
                    deprecate(apiKey)
                    
                    fetch(endpoint, id: id, completionHandler: completionHandler)
                }
                catch {
                    logger.debug("\(endpoint) with id \(id) using api key: \(apiKey) fails with error:\(error)")
                    completionHandler(.failure(error))
                }
            }
        }
        catch {
            logger.debug("\(endpoint) with id \(id) fails with error:\(error)")
            completionHandler(.failure(error))
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
            return .failure(Error.missingInformation)
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
