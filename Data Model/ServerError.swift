//
//  ServerError.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/24.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
// MARK: - 伺服器回傳的錯誤 ResponseDataModel.ServerError
extension ResponseDataModel {
    /// 伺服器回傳的錯誤，譬如說我沒付錢，用 https 的話，伺服器會回傳錯誤。
    struct ServerError {
        /// 服務商給的錯誤代碼，我不太確定是不是 HTTP 的 status code，
        /// 可以上服務商的網站查錯誤代碼的意思。
        let code: Int
        /// 服務商的文件沒說這是什麼，望文生義吧。
        let type: String?
        /// 服務商的文件沒說這是什麼，望文生義吧。
        let info: String
        
        private init(code: Int, type: String? = nil, info: String) {
#warning("寫 unit test 的時候再看看要不要把這個 init 打開")
            assertionFailure("###, \(#function), 不應該用 decode 之外的方式產生 instance。")
            
            self.code = code
            self.type = type
            self.info = info
        }
    }
}

extension ResponseDataModel.ServerError: Error {
    var localizedDescription: String {
        if let type = type {
            return "code: \(code), type: \(type), info: \(info)"
        } else {
            return "code: \(code), info: \(info)"
        }
    }
}

extension ResponseDataModel.ServerError: Decodable {
    /// JSON 第一層的 Coding Key
    enum CodingKeyForError: String, CodingKey {
        case error
    }
    
    /// JSON 第二層的 Coding Key
    enum CodingKeys: String, CodingKey {
        case code, type, info
    }
    
    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeyForError.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        
        code = try nestedContainer.decode(Int.self, forKey: .code)
        type = try? nestedContainer.decodeIfPresent(String.self, forKey: .type)
        info = try nestedContainer.decode(String.self, forKey: .info)
    }
}


