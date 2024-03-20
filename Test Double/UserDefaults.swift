import Foundation

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    final class UserDefaults: UserDefaultsProtocol {
        // MARK: - initializer
        init() {
            dataDictionary = [:]
            numberOfArchive = [:]
            numberOfUnarchive = [:]
        }
        
        // MARK: - properties
        private(set) var dataDictionary: [String: Any]
        private(set) var numberOfArchive: [String: Int]
        private(set) var numberOfUnarchive: [String: Int]
        
        // MARK: - methods
        func integer(forKey defaultName: String) -> Int {
            numberOfUnarchive[defaultName, default: 0] += 1
            return dataDictionary[defaultName] as? Int ?? 0
        }
        
        func string(forKey defaultName: String) -> String? {
            numberOfUnarchive[defaultName, default: 0] += 1
            return dataDictionary[defaultName] as? String
        }
        
        func stringArray(forKey defaultName: String) -> [String]? {
            numberOfUnarchive[defaultName, default: 0] += 1
            return dataDictionary[defaultName] as? [String]
        }
        
        func set(_ value: Any?, forKey defaultName: String) {
            guard let value else { return }
            numberOfArchive[defaultName, default: 0] += 1
            dataDictionary[defaultName] = value
        }
    }
}
