import XCTest
@testable import ImperativeCurrency

final class FetcherTests: XCTestCase {
    private var sut: Fetcher!
    
    private var currencySession: TestDouble.CurrencySession!
    private var keyManager: TestDouble.KeyManager!
    private var dummyAPIKeys: Set<String>!
    
    override func setUp() {
        dummyAPIKeys = ["a", "b", "c"]
        keyManager = TestDouble.KeyManager(unusedAPIKeys: dummyAPIKeys)
        currencySession = TestDouble.CurrencySession()
        
        sut = Fetcher(currencySession: currencySession,
                      keyManager: keyManager)
    }
    
    override func tearDown() {
        sut = nil
        currencySession = nil
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
        sut.rate { result in receivedLatestRateResult = result }
        
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
        sut.rateFor(dateString: expectedDateString) { result in receivedHistoricalRateResult = result }
        
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
            return Endpoints.TestEndpoint(url: dummyURL)
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
            return Endpoints.TestEndpoint(url: dummyURL)
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
    func testTooManyRequestRecovery() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(url: dummyURL)
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
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 能通知 key manager，key manager 更新 key 之後
    /// fetcher 重新打 api，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testTooManyRequestFallBack() throws {
        // arrange
        var receivedResult: Result<ResponseDataModel.TestDataModel, Error>?
        
        let dummyEndpoint: Endpoints.TestEndpoint = try { () -> Endpoints.TestEndpoint in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return Endpoints.TestEndpoint(url: dummyURL)
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
            let receivedResult: Result<ResponseDataModel.TestDataModel, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success:
                    XCTFail("should not receive any instance")
                case .failure(let error):
                    guard let fetcherError = error as? Fetcher.Error else {
                        XCTFail("應該要收到 Fetcher.Error")
                        return
                    }
                    
                    guard fetcherError == Fetcher.Error.tooManyRequest else {
                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
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
            return Endpoints.TestEndpoint(url: dummyURL)
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
        }
    }
    
        /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
        /// fetcher 更換新的 api key 後再次 call session 的 method，
        /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
//    func testInvalidAPIKeyFallBack() throws {
//        // arrange
//        var receivedResult: Result<ResponseDataModel.LatestRate, Error>?
//
//        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
//
//        do {
//            stubRateSession.tuple = try TestingData.SessionData.invalidAPIKey()
//        }
//
//        // act
//        sut.fetch(dummyEndpoint) { result in receivedResult = result }
//
//        // assert
//        do {
//            let receivedResult: Result<ResponseDataModel.LatestRate, Error> = try XCTUnwrap(receivedResult)
//
//            switch receivedResult {
//                case .success:
//                    XCTFail("should not receive any instance")
//                case .failure(let error):
//                    guard let fetcherError = error as? Fetcher.Error else {
//                        XCTFail("should receive Fetcher.Error")
//                        return
//                    }
//
//                    guard fetcherError == Fetcher.Error.invalidAPIKey else {
//                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
//                        return
//                    }
//            }
//        }
//    }
    
    
//
//    /// 同時 call 兩次 session 的 method，
//    /// 都回應 api key 的額度用罄，
//    /// fetcher 要只更新 api key 一次。
//    func testTooManyRequestSimultaneously() throws {
//        // arrange
//
//        let spyAPIKeySession: SpyAPIKeyRateSession = SpyAPIKeyRateSession()
//        sut = Fetcher(rateSession: spyAPIKeySession)
//
//        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
//
//        var firstReceivedResult: Result<ResponseDataModel.LatestRate, Error>?
//        var secondReceivedResult: Result<ResponseDataModel.LatestRate, Error>?
//
//        // act
//        sut.fetch(dummyEndpoint) { result in firstReceivedResult = result }
//        sut.fetch(dummyEndpoint) { result in secondReceivedResult = result }
//
//        do {
//            let tooManyRequestTuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData.SessionData.tooManyRequest()
//
//            // session 執行第一個 completion handler
//            if let firstFetcherCompletionHandler = spyAPIKeySession.completionHandlers.first {
//                firstFetcherCompletionHandler(tooManyRequestTuple.data, tooManyRequestTuple.response, tooManyRequestTuple.error)
//            }
//            else {
//                XCTFail("arrange 失誤，第一次 call `sut.fetch(:)` 應該會給 spy api key session 一個 completion handler")
//            }
//
//            // session 執行第二個 completion handler
//            if spyAPIKeySession.completionHandlers.count >= 2 {
//                let secondFetcherCompletionHandler: (Data?, URLResponse?, Error?) -> Void = spyAPIKeySession.completionHandlers[1]
//                secondFetcherCompletionHandler(tooManyRequestTuple.data, tooManyRequestTuple.response, tooManyRequestTuple.error)
//            }
//            else {
//                XCTFail("arrange 失誤，第二次 call `sut.fetch(:)` 應該會給 spy api key session 第二個 completion handler")
//            }
//
//            // 現階段 fetcher 應該還沒執行過 caller 傳進來的 completion handler
//            XCTAssertNil(firstReceivedResult)
//            XCTAssertNil(secondReceivedResult)
//        }
//
//        do {
//            let latestTuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData.SessionData.latestRate()
//
//            // session 執行第三個 completion handler
//            if spyAPIKeySession.completionHandlers.count >= 3 {
//                let thirdFetcherCompletionHandler: (Data?, URLResponse?, Error?) -> Void = spyAPIKeySession.completionHandlers[2]
//                thirdFetcherCompletionHandler(latestTuple.data, latestTuple.response, latestTuple.error)
//            }
//            else {
//                XCTFail("arrange 失誤，spy api key session 對於第一個 call 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 call 一次 session 的 method，此時 spy api key session 會收到第三個 completion handler")
//            }
//
//            // session 執行第四個 completion handler
//            if spyAPIKeySession.completionHandlers.count >= 4 {
//                let fourthFetcherCompletionHandler: (Data?, URLResponse?, Error?) -> Void = spyAPIKeySession.completionHandlers[3]
//                fourthFetcherCompletionHandler(latestTuple.data, latestTuple.response, latestTuple.error)
//            }
//            else {
//                XCTFail("arrange 失誤，spy api key session 對於第二個 call 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 call 一次 session 的 method，此時 spy api key session 會收到第四個 completion handler")
//            }
//        }
//
//        // assert
//        if spyAPIKeySession.receivedAPIKeys.count == 4 {
//            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
//            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
//        }
//        else {
//            XCTFail("spy api key session 應該要剛好收到 4 個 request")
//        }
//
//        XCTAssertNotNil(firstReceivedResult)
//        XCTAssertNotNil(secondReceivedResult)
//    }
}

// MARK: - name space: test double
extension FetcherTests { // TODO: to be removed
    private final class StubRateSession: CurrencySessionProtocol {
        var tuple: (data: Data?, response: URLResponse?, error: Error?)
        
        func rateDataTask(with request: URLRequest,
                          completionHandler: (Data?, URLResponse?, Error?) -> Void) {
            completionHandler(tuple.data, tuple.response, tuple.error)
        }
    }
    
    private final class SpyRateSession: CurrencySessionProtocol {
        // MARK: - initializer
        init() {
            outputs = []
            receivedAPIKeys = []
        }
        
        // MARK: - instance properties
        var outputs: [(data: Data?, response: URLResponse?, error: Error?)]
        
        private(set) var receivedAPIKeys: [String]
        
        // MARK: - instance method
        func rateDataTask(with request: URLRequest,
                          completionHandler: (Data?, URLResponse?, Error?) -> Void) {
            if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
                receivedAPIKeys.append(receivedAPIKey)
            }
            
            guard !(outputs.isEmpty) else { return }
            
            let output: (data: Data?, response: URLResponse?, error: Error?) = outputs.removeFirst()
            completionHandler(output.data, output.response, output.error)
        }
    }
    
    private final class SpyAPIKeyRateSession: CurrencySessionProtocol {
        // MARK: - initializer
        init() {
            completionHandlers = []
            receivedAPIKeys = []
        }
        
        // MARK: - instance properties
        private(set) var completionHandlers: [(Data?, URLResponse?, Error?) -> Void]
        
        private(set) var receivedAPIKeys: [String]
        
        // MARK: - instance method
        func rateDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
            completionHandlers.append(completionHandler)
            if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
                receivedAPIKeys.append(receivedAPIKey)
            }
        }
    }
}
