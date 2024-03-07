import Foundation

protocol UserDefaultsProtocol {
    func integer(forKey defaultName: String) -> Int
    
    func string(forKey defaultName: String) -> String?
    
    func set(_ value: Any?, forKey defaultName: String)
    
    func stringArray(forKey defaultName: String) -> [String]?
}

extension UserDefaults: UserDefaultsProtocol {}
