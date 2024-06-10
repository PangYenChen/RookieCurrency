import XCTest
@testable import ReactiveCurrency
import Combine

final class FetcherTests: XCTestCase {
    private var sut: Fetcher!
    
    private var keyManager: KeyManager!
    private var currencySession: TestDouble.CurrencySession!
    private var dummyAPIKeys: Set<String>!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        dummyAPIKeys = ["a", "b", "c"]
        keyManager = KeyManager(unusedAPIKeys: dummyAPIKeys)
        currencySession = TestDouble.CurrencySession()
        
        sut = Fetcher(keyManager: keyManager,
                      currencySession: currencySession)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut = nil
        
        currencySession = nil
        keyManager = nil
        
        dummyAPIKeys = nil
        
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
    }
    
    func testNoRetainCycleOccur() {
        // arrange
        addTeardownBlock { [weak sut] in
            // assert
            XCTAssertNil(sut)
        }
        // act
        sut = nil
    }
    
    func testPublishLatestRate() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        sut.latestRatePublisher(id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { latestRate in receivedValue = latestRate })
            .store(in: &anyCancellableSet)
        do /*currency session act*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .latestRate()
            try currencySession.publish((XCTUnwrap(tuple.data),
                                         XCTUnwrap(tuple.response)))
        }
        
        // assert
        do /*assert receivedLatestRate*/ {
            let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let receivedLatestRate: ResponseDataModel.LatestRate = try XCTUnwrap(receivedValue)
            XCTAssertNotNil(receivedLatestRate[currencyCode: dummyCurrencyCode])
            XCTAssertFalse(receivedLatestRate.rates.isEmpty)
        }
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error): XCTFail("should not receive the .failure \(error)")
                case .finished: break
            }
        }
    }
    
    func testPublishHistoricalRate() throws {
        // arrange
        var receivedValue: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyDateString: ResponseDataModel.CurrencyCode = "1970-01-01"
            sut.historicalRatePublisherFor(dateString: dummyDateString, id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { historicalRate in receivedValue = historicalRate })
                .store(in: &anyCancellableSet)
            do /*currency session act*/ {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .historicalRate(dateString: dummyDateString)
                try currencySession.publish((XCTUnwrap(tuple.data),
                                             XCTUnwrap(tuple.response)))
            }
        }
        
        // assert
        do /*assert receivedHistoricalRate*/ {
            let receivedHistoricalRate: ResponseDataModel.HistoricalRate = try XCTUnwrap(receivedValue)
            XCTAssertFalse(receivedHistoricalRate.rates.isEmpty)
            
            let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            XCTAssertNotNil(receivedHistoricalRate[currencyCode: dummyCurrencyCode])
        }
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    XCTFail("不應該收到錯誤，但收到\(error)")
                case .finished:
                    break
            }
        }
    }
    
    func testFetchSupportedSymbols() throws {
        // arrange
        var receivedValue: ResponseDataModel.SupportedSymbols?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        sut.supportedCurrencyPublisher(id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { value in receivedValue = value })
            .store(in: &anyCancellableSet)
        do /*currency session act*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .supportedSymbols()
            try currencySession.publish((XCTUnwrap(tuple.data),
                                         XCTUnwrap(tuple.response)))
        }
        
        // assert
        do /*assert receivedSupportedSymbols*/ {
            let receivedSupportedSymbols: ResponseDataModel.SupportedSymbols = try XCTUnwrap(receivedValue)
            
            XCTAssertFalse(receivedSupportedSymbols.symbols.isEmpty)
        }
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("should not receive any error, but receive: \(error)")
            }
        }
    }
    
    func testInvalidJSONData() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            sut
                .publisher(for: Endpoints.TestEndpoint(urlResult: .success(dummyURL)), id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .noContent()
            try currencySession.publish((XCTUnwrap(tuple.data),
                                         XCTUnwrap(tuple.response)))
        }
        
        // assert
        XCTAssertNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .failure(let error):
                    if !(error is DecodingError) {
                        XCTFail("should not receive error other than decoding error: \(error)")
                    }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
    }
    
    func testTimeout() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            sut
                .publisher(for: Endpoints.TestEndpoint(urlResult: .success(dummyURL)), id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .timeout()
            try currencySession.publish(completion: .failure(XCTUnwrap(tuple.error as? URLError)))
        }
        
        // assert
        XCTAssertNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .failure(let error):
                    guard let urlError = error as? URLError else {
                        XCTFail("應該要是 URLError，而不是其他 Error，例如 DecodingError。")
                        return
                    }
                    
                    guard urlError.code.rawValue == URLError.timedOut.rawValue else {
                        XCTFail("get an error other than timedOut: \(error)")
                        return
                    }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
    }

    /// 當 session 回應正在使用的 api key 的額度用罄時，
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，session 正常回應。
    func testRunOutOfQuotaRecovery() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            sut
                .publisher(for: Endpoints.TestEndpoint(urlResult: .success(dummyURL)), id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            do /*session result in too many request*/ {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .tooManyRequest()
                try currencySession.publish((XCTUnwrap(tuple.data),
                                             XCTUnwrap(tuple.response)))
            }
            
            do /*session result in success*/ {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .testTuple()
                try currencySession.publish((XCTUnwrap(tuple.data),
                                             XCTUnwrap(tuple.response)))
            }
        }
        
        // assert
        XCTAssertNotNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    XCTFail("should not receive error: \(error)")
                case .finished:
                    break
            }
        }
        
        XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testRunOutOfQuotaFallBack() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        let dummyEndpoint: Endpoints.TestEndpoint = try {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        do {
            sut
                .publisher(for: dummyEndpoint, id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            do /*session result in too many request*/ {
                for _ in 0..<dummyAPIKeys.count {
                    let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                        .CurrencySessionTuple
                        .tooManyRequest()
                    try currencySession.publish((XCTUnwrap(tuple.data),
                                                 XCTUnwrap(tuple.response)))
                }
            }
        }
        
        // assert
        XCTAssertNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .failure(let error):
                    do { throw error }
                    catch KeyManager.Error.runOutOfKey { /*intentionally left blank*/ }
                    catch { XCTFail("should receive a KeyManager.Error.runOutOfKey, but receive: \(error)") }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
        
        XCTAssertEqual(keyManager.usedAPIKeys.count, dummyAPIKeys.count)
        
        // arrange
        receivedValue = nil
        receivedCompletion = nil
        
        // act
        sut
            .publisher(for: dummyEndpoint, id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { value in receivedValue = value })
            .store(in: &anyCancellableSet)
        
        // assert
        XCTAssertNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .failure(let error):
                    guard let fetcherError = error as? KeyManager.Error else {
                        XCTFail("應該要收到 Fetcher.Error")
                        return
                    }
                    
                    guard fetcherError == KeyManager.Error.runOutOfKey else {
                        XCTFail("receive error other than Fetcher.Error.runOutOfQuota: \(error)")
                        return
                    }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            sut
                .publisher(for: Endpoints.TestEndpoint(urlResult: .success(dummyURL)), id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            do /*session result in invalid api key*/ {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .invalidAPIKey()
                try currencySession.publish((XCTUnwrap(tuple.data),
                                             XCTUnwrap(tuple.response)))
            }
            
            do /*session result in success*/ {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .testTuple()
                try currencySession.publish((XCTUnwrap(tuple.data),
                                             XCTUnwrap(tuple.response)))
            }
        }
        
        // assert
        XCTAssertNotNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("should not receive any error:\(error)")
            }
        }
        
        XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var receivedValue: ResponseDataModel.TestDataModel?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        // act
        do {
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            sut
                .publisher(for: Endpoints.TestEndpoint(urlResult: .success(dummyURL)), id: UUID().uuidString)
                .sink(receiveCompletion: { completion in receivedCompletion = completion },
                      receiveValue: { value in receivedValue = value })
                .store(in: &anyCancellableSet)
            do /*session result in invalid api key*/ {
                for _ in 0..<dummyAPIKeys.count {
                    let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                        .CurrencySessionTuple
                        .invalidAPIKey()
                    try currencySession.publish((XCTUnwrap(tuple.data),
                                                 XCTUnwrap(tuple.response)))
                }
            }
        }
        
        // assert
        XCTAssertNil(receivedValue)
        
        do /*assert receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    do { throw error }
                    catch KeyManager.Error.runOutOfKey { /*intentionally left blank*/ }
                    catch { XCTFail("should receive a KeyManager.Error.runOutOfKey, but receive: \(error)") }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
        
        XCTAssertEqual(keyManager.usedAPIKeys.count, dummyAPIKeys.count)
    }
}
