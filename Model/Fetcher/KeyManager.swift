import Foundation

class KeyManager {
    init(concurrentQueue: DispatchQueue = DispatchQueue(label: "key.manager", attributes: .concurrent),
         unusedAPIKeys: Set<String> = KeyManager.unusedAPIKeys) {
        self.concurrentQueue = concurrentQueue
        
        self.unusedAPIKeys = unusedAPIKeys
        
        if let unusedAPIKey = self.unusedAPIKeys.popFirst() {
            usingAPIKeyResult = .success(unusedAPIKey)
        }
        else {
            usingAPIKeyResult = .failure(Error.runOutOfKey)
        }
        
        self.usedAPIKeys = []
    }
    
    private let concurrentQueue: DispatchQueue
    
    private var unusedAPIKeys: Set<String>
    private var usingAPIKeyResult: Result<String, Error>
    private var usedAPIKeys: Set<String> = []
    
#if DEBUG
    var apiKeysUsageRatio: Double {
        let totalAPIKeyCount: Int = usedAPIKeys.count + 1 + unusedAPIKeys.count
        return Double(usedAPIKeys.count) / Double(totalAPIKeyCount)
    }
#endif
}

extension KeyManager {
    func getUsingAPIKeyAfterDeprecating(_ apiKeyToBeDeprecated: String) -> Result<String, Error> {
        concurrentQueue.sync(flags: .barrier) {
            guard case let .success(usingAPIKey) = usingAPIKeyResult else { return .failure(.runOutOfKey) }
            guard apiKeyToBeDeprecated == usingAPIKey else { return .success(usingAPIKey) }
            
            if let unusedAPIKey = unusedAPIKeys.popFirst() {
                usedAPIKeys.insert(apiKeyToBeDeprecated)
                usingAPIKeyResult = .success(unusedAPIKey)
            }
            else {
                usingAPIKeyResult = .failure(.runOutOfKey)
            }
            
            return usingAPIKeyResult
        }
    }
    
    func getUsingAPIKey() -> Result<String, Error> {
        concurrentQueue.sync { usingAPIKeyResult }
    }
}

extension KeyManager {
    private static let unusedAPIKeys: Set<String> = ["kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW",
                                                     "pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg",
                                                     "R7fbgnoWFqhDtzxrfbYNgTbRJqLcNplL",
                                                     "02aTmnyTuDcfXXdo4AruyhfsW3vDVCD4"]
    
    static let shared: KeyManager = KeyManager()
}

extension KeyManager {
    enum Error: LocalizedError {
        case runOutOfKey
        
        var localizedDescription: String {
            switch self {
                case .runOutOfKey: return "" // TODO:
            }
        }
    }
}
