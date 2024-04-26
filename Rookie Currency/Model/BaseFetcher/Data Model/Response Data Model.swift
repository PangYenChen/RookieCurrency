import Foundation

/// 這是一個命名空間，容納服務商回傳的資料所對應到的資料結構
enum ResponseDataModel {}

// MARK: - JSONDecoder and JSONEncoder
extension ResponseDataModel {
    static let jsonDecoder: JSONDecoder = JSONDecoder()
    
    static let jsonEncoder: JSONEncoder = {
        let jsonEncoder: JSONEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }()
}
