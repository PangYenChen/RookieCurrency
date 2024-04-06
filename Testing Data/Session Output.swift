import Foundation
import XCTest

extension TestingData {
    enum CurrencySessionTuple {
        static func latestRate() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.latestData
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 200
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            return (data, response, nil)
        }
        
        static func historicalRate(dateString: String) throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.historicalRateDataFor(dateString: dateString)
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 200
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            
            return (data, response, nil)
        }
        
        static func noContent() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data = Data()
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 204
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            return (data, response, nil)
        }
        
        static func timeout() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            (nil, nil, URLError(URLError.timedOut))
        }
        
        static func tooManyRequest() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.tooManyRequestData
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 429
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
        
        static func invalidAPIKey() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.invalidAPIKeyData
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 401
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
        
        static func supportedSymbols() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.supportedSymbols
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 200
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
        
        static func testTuple() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data: Data? = TestingData.testData
            let url: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let statusCode: Int = 200
            
            let response: HTTPURLResponse? = HTTPURLResponse(url: url,
                                                             statusCode: statusCode,
                                                             httpVersion: nil,
                                                             headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
    }
}
