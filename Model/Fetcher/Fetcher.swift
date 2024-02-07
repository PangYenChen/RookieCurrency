import Foundation

/// 跟伺服器拿資料的物件
class Fetcher {
    // MARK: - initializer
    init(rateSession: RateSession = Fetcher.rateSession) {
        self.rateSession = rateSession
        
        jsonDecoder = ResponseDataModel.jsonDecoder
        concurrentQueue = DispatchQueue(label: "read write lock for api keys")
    }
    
    // MARK: - instance properties
    let rateSession: RateSession

    let jsonDecoder: JSONDecoder
    
    private let concurrentQueue: DispatchQueue
    
    // MARK: api key 相關的 properties
    // TODO: 這三個 private properties 應該可以抽成一個物件
    private var unusedAPIKeys: Set<String> = ["pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg", "R7fbgnoWFqhDtzxrfbYNgTbRJqLcNplL"]
    
    private  var usingAPIKey: String = "kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW"
    
    private var usedAPIKeys: Set<String> = []
    
#if DEBUG
    var apiKeysUsageRatio: Double {
        let totalAPIKeyCount: Int = usedAPIKeys.count + 1 + unusedAPIKeys.count
        return Double(usedAPIKeys.count) / Double(totalAPIKeyCount)
    }
#endif
}

// MARK: - static properties
extension Fetcher {
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
extension Fetcher {
    /// 不暫存的 session
    private static let rateSession: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        return URLSession(configuration: configuration)
    }()
}

// MARK: - helper method
extension Fetcher {
    /// 產生 timeout 時限為 5 秒，且帶上 api key 的 `URLRequest`
    /// - Parameter url: The URL to be retrieved.
    /// - Returns: The new url request.
    func createRequest(url: URL, withAPIKey apiKey: String) -> URLRequest {
        var urlRequest: URLRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
    
    /// 更新正在使用的 api key
    /// 若還有新的 api key 可以用，換上後回傳 true，表示要重打 api。
    /// 若已無 api key 可用，回傳 false，讓 call cite 處理。
    /// - Returns: 是否需要從打一次 api
    func updateAPIKeySucceed(apiKeyToBeDeprecated: String) -> Bool {
        concurrentQueue.sync(flags: .barrier) {
            if apiKeyToBeDeprecated == usingAPIKey {
                // 正在用的 api key 要被換掉
                if unusedAPIKeys.isEmpty {
                    // 已經沒有 api key 可以用了。
                    return false
                }
                else {
                    // 已經換上新的 api key，需要從打一次 api
                    usedAPIKeys.insert(usingAPIKey)
                    usingAPIKey = unusedAPIKeys.removeFirst()
                    return true
                }
            }
            else {
                // 要被換掉的 api key 已經被其他隻 api 換掉了
                return true
            }
        }
    }
    
    func getUsingAPIKey() -> String {
        concurrentQueue.sync { usingAPIKey }
    }
}

// MARK: - name space
extension Fetcher {
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
