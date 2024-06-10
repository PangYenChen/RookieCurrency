import XCTest
@testable import ImperativeCurrency

final class FetcherTests: XCTestCase {
    private var sut: Fetcher!
    
    private var currencySession: TestDouble.CurrencySession!
    private var keyManager: KeyManager!
    private var dummyAPIKeys: Set<String>!
    
    override func setUp() {
        dummyAPIKeys = ["a", "b", "c"]
        keyManager = KeyManager(unusedAPIKeys: dummyAPIKeys)
        currencySession = TestDouble.CurrencySession()
        
        sut = Fetcher(keyManager: keyManager,
                      currencySession: currencySession)
    }
    
    override func tearDown() {
        sut = nil
        
        currencySession = nil
        keyManager = nil
        dummyAPIKeys = nil
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
    
    func testFetchLatestRate() throws {
        // arrange
        var receivedLatestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        
        // act
        sut.latestRate(id: UUID().uuidString) { result in receivedLatestRateResult = result }
        
        do {
            let latestRateTuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData.CurrencySessionTuple.latestRate()
            currencySession.executeCompletionHandler(with: latestRateTuple.data,
                                                     latestRateTuple.response,
                                                     latestRateTuple.error)
        }
        
        // assert
        do {
            let receivedLatestRateResult: Result<ResponseDataModel.LatestRate, Error> = try XCTUnwrap(receivedLatestRateResult)
            
            switch receivedLatestRateResult {
                case .success(let latestRate):
                    XCTAssertFalse(latestRate.rates.isEmpty)
                    
                    let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
                    XCTAssertNotNil(latestRate[currencyCode: dummyCurrencyCode])
                case .failure(let error):
                    XCTFail("不應該發生錯誤，卻收到\(error)")
            }
        }
    }
    
    func testFetchHistoricalRate() throws {
        // arrange
        var receivedHistoricalRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        
        let expectedDateString: ResponseDataModel.CurrencyCode = "1970-01-01"
        
        // act
        sut.historicalRateFor(dateString: expectedDateString, id: UUID().uuidString) { result in receivedHistoricalRateResult = result }
        
        do {
            let historicalRateTuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .historicalRate(dateString: expectedDateString)
            currencySession.executeCompletionHandler(with: historicalRateTuple.data,
                                                     historicalRateTuple.response,
                                                     historicalRateTuple.error)
        }
        
        // assert
        do {
            let receivedHistoricalRateResult: Result<ResponseDataModel.HistoricalRate, Error> = try XCTUnwrap(receivedHistoricalRateResult)
            
            switch receivedHistoricalRateResult {
                case .success(let historicalRate):
                    XCTAssertFalse(historicalRate.rates.isEmpty)
                    
                    let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
                    XCTAssertNotNil(historicalRate[currencyCode: dummyCurrencyCode])
                    
                case .failure(let error):
                    XCTFail("不應該收到錯誤，卻收到\(error)")
            }
        }
    }
    
    func testFetchSupportedSymbols() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.SupportedSymbols, Error>?
        
        // act
        sut.supportedCurrency { result in receivedResult = result }
        do {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .supportedSymbols()
            
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.SupportedSymbols, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success(let supportedSymbols):
                    XCTAssertFalse(supportedSymbols.symbols.isEmpty)
                case .failure(let failure):
                    XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
    }
    
    func testInvalidJSONData() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .noContent()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success:
                    XCTFail("should fail to decode")
                case .failure(let error):
                    if !(error is DecodingError) {
                        XCTFail("get an error other than decoding error: \(error)")
                    }
            }
        }
    }
    
    func testTimeout() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do /*session result in timeout*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .timeout()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            switch receivedResult {
                case .success:
                    XCTFail("should time out")
                case .failure(let error):
                    guard let urlError = error as? URLError else {
                        XCTFail("應該要是 URLError，而不是其他 Error，例如 DecodingError。")
                        return
                    }
                    
                    guard urlError.code.rawValue == URLError.timedOut.rawValue else {
                        XCTFail("get an error other than timedOut: \(error)")
                        return
                    }
            }
        }
    }
    
    /// 當 session 回應正在使用的 api key 的額度用罄時，
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，session 正常回應。
    func testRunOutOfQuotaRecovery() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do /*session result in too many request*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .tooManyRequest()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        do /*session result in success*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .testTuple()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success:
                    XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
                case .failure:
                    XCTFail("should not get any error")
            }
            
            XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testRunOutOfQuotaFallBack() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do /*session result in too many request*/ {
            for _ in 0..<dummyAPIKeys.count {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .tooManyRequest()
                currencySession.executeCompletionHandler(with: tuple.data,
                                                         tuple.response,
                                                         tuple.error)
            }
        }
        
        // assert
        do {
            do { try XCTUnwrap(receivedResult).get() }
            catch KeyManager.Error.runOutOfKey { /*intentionally left blank*/ }
            catch { XCTFail("should receive a KeyManager.Error.runOutOfKey, but receive: \(error)") }
            
            XCTAssertEqual(keyManager.usedAPIKeys.count, dummyAPIKeys.count)
        }
        
        // arrange
        receivedResult = nil
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success:
                    XCTFail("should not receive any instance")
                case .failure(let error):
                    guard let fetcherError = error as? KeyManager.Error else {
                        XCTFail("應該要收到 Fetcher.Error")
                        return
                    }
                    
                    guard fetcherError == KeyManager.Error.runOutOfKey else {
                        XCTFail("receive error other than Fetcher.Error.runOutOfQuota: \(error)")
                        return
                    }
            }
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do /*session result in invalid api key*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .invalidAPIKey()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        do /*session result in success*/ {
            let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                .CurrencySessionTuple
                .testTuple()
            currencySession.executeCompletionHandler(with: tuple.data,
                                                     tuple.response,
                                                     tuple.error)
        }
        
        // assert
        do {
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success:
                    XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
                case .failure:
                    XCTFail("should not receive any error")
            }
            
            XCTAssertEqual(keyManager.usedAPIKeys.count, 1)
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(urlResult: .success(dummyURL))
        }()
        
        // act
        sut.fetch(dummyEndpoint) { result in receivedResult = result }
        
        do /*session result in invalid api key*/ {
            for _ in 0..<dummyAPIKeys.count {
                let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
                    .CurrencySessionTuple
                    .invalidAPIKey()
                currencySession.executeCompletionHandler(with: tuple.data,
                                                         tuple.response,
                                                         tuple.error)
            }
        }
        
        // assert
        do {
            do { try XCTUnwrap(receivedResult).get() }
            catch KeyManager.Error.runOutOfKey { /*intentionally left blank*/ }
            catch { XCTFail("should receive a KeyManager.Error.runOutOfKey, but receive: \(error)") }
            
            XCTAssertEqual(keyManager.usedAPIKeys.count, dummyAPIKeys.count)
        }
    }
}
