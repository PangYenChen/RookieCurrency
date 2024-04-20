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
    /// 產生 timeout 時限為 5 秒，且帶上 api key 的 `URLRequest`
    /// - Parameter url: The URL to be retrieved.
    /// - Returns: The new url request.
    func createRequest(url: URL, withAPIKey apiKey: String) -> URLRequest {
        let timeoutInterval: TimeInterval = 5
        var urlRequest: URLRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
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
            // 這個專案的 request 都是 http request，依照文件所說，收到的 response 可以 down cast 成 http url response。
            return .failure(.unknownError)
        }
    }
}

// MARK: - name space
extension BaseFetcher {
    enum Error: LocalizedError {
        case invalidAPIKey
        case runOutOfQuota
        case unknownError
        
        var localizedDescription: String {
            switch self {
                case .invalidAPIKey: R.string.share.invalidAPIKey()
                case .runOutOfQuota: R.string.share.runOutOfQuota()
                case .unknownError: R.string.share.noDataNoError()
            }
        }
        
        var errorDescription: String? { localizedDescription }
    }
}

// MARK: - static properties
extension BaseFetcher {
    static let urlComponents: URLComponents = {
        /// 拿匯率的 base url。
        /// 提供資料的服務商集團： https://apilayer.com/marketplace/category/currency
        /// 服務商之一："https://api.apilayer.com/fixer/"
        /// 服務商之二："https://api.apilayer.com/exchangerates_data"
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.apilayer.com"
        urlComponents.path = "/exchangerates_data"
        
        return urlComponents
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
