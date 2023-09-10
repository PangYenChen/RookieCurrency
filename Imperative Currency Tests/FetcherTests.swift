import XCTest
@testable import ImperativeCurrency

final class FetcherTests: XCTestCase {
    
    private var sut: Fetcher!
    
    private var stubRateSession: StubRateSession!
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `LatestRate` instance
    func testFetchLatestRate() throws {
        
        // arrange
        var expectedLatestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        
        do {
            stubRateSession.tuple = try TestingData.SessionData.latestRate()
        }
        
        // act
        sut.fetch(Endpoints.Latest()) { result in expectedLatestRateResult = result }
        
        // assert
        do {
            let expectedLatestRateResult = try XCTUnwrap(expectedLatestRateResult)
            
            switch expectedLatestRateResult {
            case .success(let latestRate):
                XCTAssertFalse(latestRate.rates.isEmpty)
                
                let dummyCurrencyCode = "TWD"
                XCTAssertNotNil(latestRate[currencyCode: dummyCurrencyCode])
            case .failure(let error):
                XCTFail("不應該發生錯誤，卻收到\(error)")
            }
        }
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `HistoricalRate` instance
    func testFetchHistoricalRate() throws {
        
        // arrange
        var expectedHistoricalRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        
        let dummyDateString = "1970-01-01"
        
        do {
            stubRateSession.tuple = try TestingData.SessionData.historicalRate(dateString: dummyDateString)
        }
        
        // act
        sut.fetch(Endpoints.Historical(dateString: dummyDateString)) { result in expectedHistoricalRateResult = result }
        
        // assert
        do {
            let expectedHistoricalRateResult = try XCTUnwrap(expectedHistoricalRateResult)
            
            switch expectedHistoricalRateResult {
            case .success(let historicalRate):
                XCTAssertFalse(historicalRate.rates.isEmpty)
                
                let dummyCurrencyCode = "TWD"
                XCTAssertNotNil(historicalRate[currencyCode: dummyCurrencyCode])
                
            case .failure(let error):
                XCTFail("不應該收到錯誤，卻收到\(error)")
            }
        }
    }
    
    /// 當 session 回傳無法 decode 的 json data 時，要能回傳 decoding error
    func testInvalidJSONData() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.tuple = try TestingData.SessionData.noContent()
        }
        
        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            
            case .success:
                XCTFail("should fail to decode")
            case .failure(let error):
                if !(error is DecodingError) {
                    XCTFail("get an error other than decoding error: \(error)")
                }
            }
        }
    }
    
    /// 當 session 回傳 timeout 時，fetcher 能確實回傳 timeout
    func testTimeout() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            stubRateSession.tuple = try TestingData.SessionData.timeout()
        }
        
        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            switch expectedResult {
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
    /// fetcher 能更換新的 api key 後重新 call session 的 method，
    /// 且新的 api key 尚有額度，session 正常回應。
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            // first response
            let tooManyRequestTuple = try TestingData.SessionData.tooManyRequest()
            spyRateSession.outputs.append(tooManyRequestTuple)
        }

        do {
            // second response
            let latestTuple = try TestingData.SessionData.latestRate()
            spyRateSession.outputs.append(latestTuple)
        }

        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
            case .failure:
                XCTFail("should not get any error")
            }
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 更新 api key，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testTooManyRequestFallBack() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.tuple = try TestingData.SessionData.tooManyRequest()
        }
        
        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
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
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)

        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()

        do {
            // first response
            let invalidAPIKeyTuple = try TestingData.SessionData.invalidAPIKey()
            spyRateSession.outputs.append(invalidAPIKeyTuple)
        }

        do {
            // second response
            let latestTuple = try TestingData.SessionData.latestRate()
            spyRateSession.outputs.append(latestTuple)
        }

        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result
        }

        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
            case .failure:
                XCTFail("should not receive any error")
            }
        }
    }

    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            stubRateSession.tuple = try TestingData.SessionData.invalidAPIKey()
        }
        
        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTFail("should not receive any instance")
            case .failure(let error):
                guard let fetcherError = error as? Fetcher.Error else {
                    XCTFail("should receive Fetcher.Error")
                    return
                }
                
                guard fetcherError == Fetcher.Error.invalidAPIKey else {
                    XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    return
                }
            }
        }
    }

    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `SupportedSymbols` instance
    func testFetchSupportedSymbols() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.SupportedSymbols, Error>?

        do {
            stubRateSession.tuple = try TestingData.SessionData.supportedSymbols()
        }

        // act
        sut.fetch(Endpoints.SupportedSymbols()) { result in expectedResult = result }

        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)

            switch expectedResult {
            case .success(let supportedSymbols):
                XCTAssertFalse(supportedSymbols.symbols.isEmpty)
            case .failure(let failure):
                XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
    }

    /// 同時 call 兩次 session 的 method，
    /// 都回應 api key 的額度用罄，
    /// fetcher 要只更新 api key 一次。
    func testTooManyRequestSimultaneously() throws {
        // arrange

        let spyAPIKeySession = SpyAPIKeyRateSession()
        sut = Fetcher(rateSession: spyAPIKeySession)
        
        let dummyEndpoint = Endpoints.Latest()
        
        var firstExpectedResult: Result<ResponseDataModel.LatestRate, Error>?
        var secondExpectedResult: Result<ResponseDataModel.LatestRate, Error>?

        // act
        sut.fetch(dummyEndpoint) { result in firstExpectedResult = result }
        sut.fetch(dummyEndpoint) { result in secondExpectedResult = result }

        do {
            let tooManyRequestTuple = try TestingData.SessionData.tooManyRequest()
            
            // session 執行第一個 completion handler
            if let firstFetcherCompletionHandler = spyAPIKeySession.completionHandlers.first {
                firstFetcherCompletionHandler(tooManyRequestTuple.data, tooManyRequestTuple.response, tooManyRequestTuple.error)
            } else {
                XCTFail("arrange 失誤，第一次 call `sut.fetch(:)` 應該會給 spy api key session 一個 completion handler")
            }

            // session 執行第二個 completion handler
            if spyAPIKeySession.completionHandlers.count >= 2 {
                let secondFetcherCompletionHandler = spyAPIKeySession.completionHandlers[1]
                secondFetcherCompletionHandler(tooManyRequestTuple.data, tooManyRequestTuple.response, tooManyRequestTuple.error)
            } else  {
                XCTFail("arrange 失誤，第二次 call `sut.fetch(:)` 應該會給 spy api key session 第二個 completion handler")
            }
            
            // 現階段 fetcher 應該還沒執行過 caller 傳進來的 completion handler
            XCTAssertNil(firstExpectedResult)
            XCTAssertNil(secondExpectedResult)
        }

        do {
            let latestTuple = try TestingData.SessionData.latestRate()
            
            // session 執行第三個 completion handler
            if spyAPIKeySession.completionHandlers.count >= 3 {
                let thirdFetcherCompletionHandler = spyAPIKeySession.completionHandlers[2]
                thirdFetcherCompletionHandler(latestTuple.data, latestTuple.response, latestTuple.error)
            } else  {
                XCTFail("arrange 失誤，spy api key session 對於第一個 call 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 call 一次 session 的 method，此時 spy api key session 會收到第三個 completion handler")
            }
            
            // session 執行第四個 completion handler
            if spyAPIKeySession.completionHandlers.count >= 4 {
                let fourthFetcherCompletionHandler = spyAPIKeySession.completionHandlers[3]
                fourthFetcherCompletionHandler(latestTuple.data, latestTuple.response, latestTuple.error)
            } else  {
                XCTFail("arrange 失誤，spy api key session 對於第二個 call 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 call 一次 session 的 method，此時 spy api key session 會收到第四個 completion handler")
            }
        }

        // assert
        if spyAPIKeySession.receivedAPIKeys.count == 4 {
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
        } else {
            XCTFail("spy api key session 應該要剛好收到 4 個 request")
        }
        
        XCTAssertNotNil(firstExpectedResult)
        XCTAssertNotNil(secondExpectedResult)
    }
}

// MARK: - test double
private final class StubRateSession: RateSession {
    
    var tuple: (data: Data?, response: URLResponse?, error: Error?)
    
    func rateDataTask(with request: URLRequest,
                      completionHandler: (Data?, URLResponse?, Error?) -> Void) {
        completionHandler(tuple.data, tuple.response, tuple.error)
    }
}

private final class SpyRateSession: RateSession {
    
    var outputs: [(data: Data?, response: URLResponse?, error: Error?)]
    
    private(set) var receivedAPIKeys: [String]
    
    init() {
        outputs = []
        receivedAPIKeys = []
    }
    
    func rateDataTask(with request: URLRequest,
                      completionHandler: (Data?, URLResponse?, Error?) -> Void) {
        
        if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(receivedAPIKey)
        }
        
        guard !(outputs.isEmpty) else { return }
        
        let output = outputs.removeFirst()
        completionHandler(output.data, output.response, output.error)
    }
}

private final class SpyAPIKeyRateSession: RateSession {
    
    private(set) var completionHandlers: [(Data?, URLResponse?, Error?) -> Void]
    
    private(set) var receivedAPIKeys: [String]
    
    init() {
        completionHandlers = []
        receivedAPIKeys = []
    }
    
    func rateDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completionHandlers.append(completionHandler)
        if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(receivedAPIKey)
        }
    }
}
