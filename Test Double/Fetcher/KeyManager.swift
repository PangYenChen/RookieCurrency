#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class KeyManager: KeyManagerProtocol {
        init(unusedAPIKeys: Set<String>) {
            self.unusedAPIKeys = unusedAPIKeys
            
            if let unusedAPIKey = self.unusedAPIKeys.popFirst() {
                usingAPIKeyResult = .success(unusedAPIKey)
            }
            else {
                usingAPIKeyResult = .failure(Error.runOutOfKey)
            }
            
            usedAPIKeys = []
        }
        
        private var unusedAPIKeys: Set<String>
        private var usingAPIKeyResult: Result<String, Swift.Error>
        private(set) var usedAPIKeys: Set<String>
        
        func getUsingAPIKeyAfterDeprecating(_ apiKeyToBeDeprecated: String) -> Result<String, Swift.Error> {
            guard case let .success(usingAPIKey) = usingAPIKeyResult else { return .failure(Error.runOutOfKey) }
            guard apiKeyToBeDeprecated == usingAPIKey else { return .success(usingAPIKey) }
            
            if let unusedAPIKey = unusedAPIKeys.popFirst() {
                usedAPIKeys.insert(apiKeyToBeDeprecated)
                usingAPIKeyResult = .success(unusedAPIKey)
            }
            else {
                usingAPIKeyResult = .failure(Error.runOutOfKey)
            }
            
            return usingAPIKeyResult
        }
        
        func getUsingAPIKey() -> Result<String, Swift.Error> { usingAPIKeyResult }
        
        enum Error: Swift.Error {
            case runOutOfKey
        }
    }
}
