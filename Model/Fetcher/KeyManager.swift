import Foundation

class KeyManager {
    init(concurrentDispatchQueue: DispatchQueue = DispatchQueue(label: "key.manager", attributes: .concurrent),
         unusedAPIKeys: Set<String> = KeyManager.unusedAPIKeys) {
        self.concurrentDispatchQueue = concurrentDispatchQueue
        
        self.unusedAPIKeys = unusedAPIKeys
        
        if let unusedAPIKey = self.unusedAPIKeys.popFirst() {
            usingAPIKeyResult = .success(unusedAPIKey)
        }
        else {
            usingAPIKeyResult = .failure(Error.runOutOfKey)
        }
        
        self.usedAPIKeys = []
    }
    
    private let concurrentDispatchQueue: DispatchQueue
    
    private var unusedAPIKeys: Set<String>
    private var usingAPIKeyResult: Result<String, Swift.Error>
    private var usedAPIKeys: Set<String> = []
    
#if DEBUG
    var apiKeysUsageRatio: Double {
        let totalAPIKeyCount: Int = usedAPIKeys.count + 1 + unusedAPIKeys.count
        return Double(usedAPIKeys.count) / Double(totalAPIKeyCount)
    }
#endif
}

extension KeyManager: KeyManagerProtocol {
    func getUsingAPIKeyAfterDeprecating(_ apiKeyToBeDeprecated: String) -> Result<String, Swift.Error> {
        concurrentDispatchQueue.sync(flags: .barrier) {
            guard case let .success(usingAPIKey) = usingAPIKeyResult else { return .failure(Error.runOutOfKey) }
            guard apiKeyToBeDeprecated == usingAPIKey else { return .success(usingAPIKey) }
            
            if let unusedAPIKey = unusedAPIKeys.popFirst() {
                usingAPIKeyResult = .success(unusedAPIKey)
            }
            else {
                usingAPIKeyResult = .failure(Error.runOutOfKey)
            }
            usedAPIKeys.insert(apiKeyToBeDeprecated) // TODO: test case 漏測了
            
            return usingAPIKeyResult
        }
    }
    
    func getUsingAPIKey() -> Result<String, Swift.Error> {
        concurrentDispatchQueue.sync { usingAPIKeyResult }
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
