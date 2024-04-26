import Foundation

/// 跟伺服器拿資料的物件
class BaseFetcher {
    // MARK: - initializer
    init(keyManager: KeyManager,
         currencySession: CurrencySessionProtocol) {
        threadSafeKeyManager = ThreadSafeWrapper<KeyManager>(wrappedValue: keyManager)
        self.currencySession = currencySession
        
        jsonDecoder = ResponseDataModel.jsonDecoder
    }
    
    // MARK: - instance properties
    let threadSafeKeyManager: ThreadSafeWrapper<KeyManager>
    let currencySession: CurrencySessionProtocol
    
    let jsonDecoder: JSONDecoder
}

// MARK: - helper method
extension BaseFetcher {
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
    
    func deprecate(_ apiKeyToBeDeprecated: String) {
        threadSafeKeyManager.writeAsynchronously { keyManager in
            keyManager.deprecate(apiKeyToBeDeprecated)
            return keyManager
        }
    }
}

extension BaseFetcher: BaseHistoricalRateProviderProtocol {
    func removeAllStorage() { /*do nothing*/ }
}

extension BaseFetcher {
    func venderResultFor(data: Data, urlResponse: URLResponse) -> Result<Data, Error> {
        let statusCodeForInvalidAPIKey: Int = 401
        let statusCodeForRunOutOfQuota: Int = 429
        
        if let httpURLResponse = urlResponse as? HTTPURLResponse {
            if httpURLResponse.statusCode == statusCodeForInvalidAPIKey {
                return .failure(.invalidAPIKey)
            }
            else if httpURLResponse.statusCode == statusCodeForRunOutOfQuota {
                return .failure(.runOutOfQuota)
            }
            else {
                return .success(data)
            }
        }
        else {
            return .failure(.nonHTTPResponse)
        }
    }
}

// MARK: - name space
extension BaseFetcher {
    enum Error: LocalizedError {
        case invalidAPIKey
        case runOutOfQuota
        /// 這個專案的 request 都是 http request，依照官方文件所說，
        /// 收到的 response 可以 down cast 成 http url response。
        /// 這個 case 只是為了補足程式上的邏輯。
        case nonHTTPResponse
        /// 用以表示 imperative api 收到的 data、urlResponse、error 中，
        /// data 跟 urlResponse 至少有一為 nil，且 error 為 nil。
        /// 依照官方文件所述，這不會發生。
        /// 這個 case 只是為了補足程式上的邏輯。
        case missingInformation
        
        var localizedDescription: String {
            switch self {
                case .invalidAPIKey: R.string.share.invalidAPIKey()
                case .runOutOfQuota: R.string.share.runOutOfQuota()
                case .nonHTTPResponse: R.string.share.nonHTTPResponse()
                case .missingInformation: R.string.share.missingInformation()
            }
        }
        
        var errorDescription: String? { localizedDescription }
    }
}

// MARK: - static properties
extension BaseFetcher {
    static let baseURLComponents: URLComponents = {
        /// 拿匯率的 base url。
        /// 提供資料的服務商集團： https://apilayer.com/marketplace/category/currency
        /// 服務商之一："https://api.apilayer.com/fixer/"
        /// 服務商之二："https://api.apilayer.com/exchangerates_data"
        
        var baseURLComponents: URLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = "api.apilayer.com"
        baseURLComponents.path = "/exchangerates_data"
        
        return baseURLComponents
    }()
    
    /// 不暫存的 session
    static let currencySession: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        return URLSession(configuration: configuration)
    }()
}

extension Fetcher {
    static let shared: Fetcher = Fetcher(keyManager: KeyManager.shared,
                                         currencySession: BaseFetcher.currencySession)
}
