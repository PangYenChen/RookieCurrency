import Foundation

class KeyManager {
    init(unusedAPIKeys: Set<String> = KeyManager.unusedAPIKeys) {
        self.unusedAPIKeys = unusedAPIKeys
        
        if let unusedAPIKey = self.unusedAPIKeys.popFirst() {
            usingAPIKeyResult = .success(unusedAPIKey)
        }
        else {
            usingAPIKeyResult = .failure(Error.runOutOfKey)
        }
        
        self.usedAPIKeys = []
    }
    
    private var unusedAPIKeys: Set<String>
    private(set) var usingAPIKeyResult: Result<String, Swift.Error>
    private(set) var usedAPIKeys: Set<String> = []
    
#if DEBUG
    var apiKeysUsageRatio: Double {
        let totalAPIKeyCount: Int = usedAPIKeys.count + 1 + unusedAPIKeys.count
        return Double(usedAPIKeys.count) / Double(totalAPIKeyCount)
    }
#endif
}

extension KeyManager {
    func deprecate(_ apiKeyToBeDeprecated: String) {
        guard case let .success(usingAPIKey) = usingAPIKeyResult else { return }
        guard apiKeyToBeDeprecated == usingAPIKey else { return }
        
        if let unusedAPIKey = unusedAPIKeys.popFirst() {
            usingAPIKeyResult = .success(unusedAPIKey)
        }
        else {
            usingAPIKeyResult = .failure(Error.runOutOfKey)
        }
        
        usedAPIKeys.insert(apiKeyToBeDeprecated)
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
                case .runOutOfKey: return R.string.share.runOutOfAPIKey()
            }
        }
    }
}
