import Foundation

/// 跟伺服器拿資料的物件
class BaseFetcher {
    // MARK: - initializer
    init(rateSession: RateSession = BaseFetcher.rateSession,
         keyManager: KeyManager = KeyManager.shared) {
        self.rateSession = rateSession
        self.keyManager = keyManager
        
        jsonDecoder = ResponseDataModel.jsonDecoder
        concurrentQueue = DispatchQueue(label: "read write lock for api keys")
    }
    
    // MARK: - instance properties
    let rateSession: RateSession

    let jsonDecoder: JSONDecoder
    
    private let concurrentQueue: DispatchQueue
    
    let keyManager: KeyManager
}

// MARK: - static properties
extension BaseFetcher {
    /// singleton object
    static let shared: Fetcher = .init()
    
    static let urlComponents: URLComponents? = {
        /// 拿匯率的 base url。
        /// 提供資料的服務商集團： https://apilayer.com/marketplace/category/currency
        /// 服務商之一："https://api.apilayer.com/fixer/"
        /// 服務商之二："https://api.apilayer.com/exchangerates_data"
        let baseURLString: String = "https://api.apilayer.com/exchangerates_data/"
        
        return URLComponents(string: baseURLString)
    }()
}

// MARK: - static property
extension BaseFetcher {
    /// 不暫存的 session
    private static let rateSession: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        return URLSession(configuration: configuration)
    }()
}

// MARK: - helper method
extension BaseFetcher {
    /// 產生 timeout 時限為 5 秒，且帶上 api key 的 `URLRequest`
    /// - Parameter url: The URL to be retrieved.
    /// - Returns: The new url request.
    func createRequest(url: URL, withAPIKey apiKey: String) -> URLRequest {
        var urlRequest: URLRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
}

extension BaseFetcher: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() { /*do nothing*/ }
}

// MARK: - name space
extension BaseFetcher {
    enum Error: LocalizedError {
        case unknownError
        case tooManyRequest
        case invalidAPIKey
        
        var localizedDescription: String {
            switch self {
                case .unknownError: R.string.share.noDataNoError()
                case .tooManyRequest: R.string.share.tooManyRequest()
                case .invalidAPIKey: R.string.share.invalidAPIKey()
            }
        }
        
        var errorDescription: String? { localizedDescription }
    }
}
