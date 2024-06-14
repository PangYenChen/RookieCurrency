import Foundation

class Fetcher: BaseFetcher {
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        traceIdentifier: String,
        resultHandler: @escaping ResultHandler<Endpoint.ResponseType>
    ) {
        do {
            let (urlRequest, apiKey): (URLRequest, String) = try createRequestTupleFor(endpoint)
                .get()
            
            logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), starts requesting, api key: \(apiKey)")
            
            currencySession.currencyDataTask(with: urlRequest) { [unowned self] data, urlResponse, error in
                do {
                    let data: Data = try venderResultFor(data: data, urlResponse: urlResponse, error: error)
                        .get()
                    
                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), receive data, api key: \(apiKey)")
                    resultHandler(Result { try jsonDecoder.decode(Endpoint.ResponseType.self, from: data) })
                }
                catch Error.invalidAPIKey, Error.runOutOfQuota {
                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), deprecates api key: \(apiKey)")
                    deprecate(apiKey)
                    
                    fetch(endpoint, traceIdentifier: traceIdentifier, resultHandler: resultHandler)
                }
                catch {
                    logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), fails with error:\(error), api key: \(apiKey)")
                    resultHandler(.failure(error))
                }
            }
        }
        catch {
            logger.debug("trace identifier: \(traceIdentifier), endpoint: \(endpoint), fails with error:\(error)")
            resultHandler(.failure(error))
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
                           traceIdentifier: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        fetch(Endpoints.Historical(dateString: dateString), traceIdentifier: traceIdentifier, resultHandler: resultHandler)
    }
}

extension Fetcher: LatestRateProviderProtocol {
    func latestRate(traceIdentifier: String, resultHandler: @escaping LatestRateResultHandler) {
        fetch(Endpoints.Latest(), traceIdentifier: traceIdentifier, resultHandler: resultHandler)
    }
}

extension Fetcher: SupportedCurrencyProviderProtocol {
    func supportedCurrency(traceIdentifier: String, resultHandler: @escaping SupportedCurrencyResultHandler) {
        fetch(Endpoints.SupportedSymbols(), traceIdentifier: traceIdentifier, resultHandler: resultHandler)
    }
}

extension Fetcher {
    typealias ResultHandler<ResponseType> = (_ result: Result<ResponseType, Swift.Error>) -> Void
}
