import XCTest
@testable import ReactiveCurrency
import Combine

class FetcherTests: XCTestCase {
    private var sut: Fetcher!
    
    private var stubRateSession: StubRateSession!
    
    private var anyCancellableSet: Set<AnyCancellable> = Set<AnyCancellable>()
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = Set<AnyCancellable>()
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
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `LatestRate` instance
    func testPublishLatestRate() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.latestRate())
        }
        
        // act
        sut.publisher(for: Endpoints.Latest())
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { latestRate in receivedValue = latestRate }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let receivedLatestRate: ResponseDataModel.LatestRate = try XCTUnwrap(receivedValue)
            XCTAssertNotNil(receivedLatestRate[currencyCode: dummyCurrencyCode])
            XCTAssertFalse(receivedLatestRate.rates.isEmpty)
        }
        
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error): XCTFail("should not receive the .failure \(error)")
                case .finished: break
            }
        }
    }
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `HistoricalRate` instance
    func testPublishHistoricalRate() throws {
        // arrange
        var receivedValue: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyDateString: ResponseDataModel.CurrencyCode = "1970-01-01"
        
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.historicalRate(dateString: dummyDateString))
        }
        
        // act
        sut.publisher(for: Endpoints.Historical(dateString: dummyDateString))
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { historicalRate in receivedValue = historicalRate }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    XCTFail("不應該收到錯誤，但收到\(error)")
                case .finished:
                    break
            }
        }
        
        do {
            let receivedHistoricalRate: ResponseDataModel.HistoricalRate = try XCTUnwrap(receivedValue)
            XCTAssertFalse(receivedHistoricalRate.rates.isEmpty)
            
            let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            XCTAssertNotNil(receivedHistoricalRate[currencyCode: dummyCurrencyCode])
        }
    }
    
    /// 當 session 回傳無法 decode 的 json data 時，要能回傳 decoding error
    func testInvalidJSONData() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.noContent())
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
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
        
        do {
            XCTAssertNil(receivedValue)
        }
    }
    
    /// 當 session 回傳 timeout 時，fetcher 能確實回傳 timeout
    func testTimeout() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.timeout())
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
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
        
        do {
            XCTAssertNil(receivedValue)
        }
    }
    
    /// 當 session 回應正在使用的 api key 的額度用罄時，
    /// fetcher 能更換新的 api key 後重新 call session 的 method，
    /// 且新的 api key 尚有額度，session 正常回應。
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession: SpyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        
        do {
            // first response
            let outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError> = try sessionDataPublisher(TestingData.SessionData.tooManyRequest())
            
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        do {
            // second response
            let outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError> = try sessionDataPublisher(TestingData.SessionData.latestRate())
            
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    XCTFail("should not receive error: \(error)")
                case .finished:
                    break
            }
        }
        
        do {
            XCTAssertNotNil(receivedValue)
            XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 更新 api key，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testTooManyRequestFallBack() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.tooManyRequest())
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .failure(let error):
                    guard let fetcherError = error as? Fetcher.Error else {
                        XCTFail("應該要收到 Fetcher.Error")
                        return
                    }
                    
                    guard fetcherError == Fetcher.Error.tooManyRequest else {
                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                        return
                    }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(receivedValue)
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        let spyRateSession: SpyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        do {
            // first output
            let outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError> = try sessionDataPublisher(TestingData.SessionData.invalidAPIKey())
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        do {
            // second output
            let outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError> = try sessionDataPublisher(TestingData.SessionData.latestRate())
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("should not receive any error:\(error)")
            }
        }
        
        do {
            XCTAssertNotNil(receivedValue)
            XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var receivedValue: ResponseDataModel.LatestRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.invalidAPIKey())
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .failure(let error):
                    guard let fetcherError = error as? Fetcher.Error else {
                        XCTFail("should receive Fetcher.Error")
                        return
                    }
                    
                    guard fetcherError == Fetcher.Error.invalidAPIKey else {
                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                        return
                    }
                case .finished:
                    XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(receivedValue)
        }
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `SupportedSymbols` instance
    func testFetchSupportedSymbols() throws {
        // arrange
        var receivedValue: ResponseDataModel.SupportedSymbols?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        do {
            stubRateSession.outputPublisher = try sessionDataPublisher(TestingData.SessionData.supportedSymbols())
        }
        
        // act
        sut.publisher(for: Endpoints.SupportedSymbols())
            .sink(
                receiveCompletion: { completion in receivedCompletion = completion },
                receiveValue: { value in receivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("should not receive any error, but receive: \(error)")
            }
        }
        
        do {
            let receivedSupportedSymbols: ResponseDataModel.SupportedSymbols = try XCTUnwrap(receivedValue)
            
            XCTAssertFalse(receivedSupportedSymbols.symbols.isEmpty)
        }
    }
    
    /// 同時 call 兩次 session 的 method，
    /// 都回應 api key 的額度用罄，
    /// fetcher 要只更新 api key 一次。
    func testTooManyRequestSimultaneously() throws {
        // arrange
        let spyAPIKeySession: SpyAPIKeyRateSession = SpyAPIKeyRateSession()
        sut = Fetcher(rateSession: spyAPIKeySession)
        
        let dummyEndpoint: Endpoints.Latest = Endpoints.Latest()
        
        var firstReceivedValue: ResponseDataModel.LatestRate?
        var firstReceivedCompletion: Subscribers.Completion<Error>?
        
        var secondReceivedValue: ResponseDataModel.LatestRate?
        var secondReceivedCompletion: Subscribers.Completion<Error>?
        
        // act
        sut.publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in firstReceivedCompletion = completion },
                receiveValue: { value in firstReceivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        sut.publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in secondReceivedCompletion = completion },
                receiveValue: { value in secondReceivedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        do {
            let tooManyRequestTuple: (data: Data?, response: URLResponse?, error: Error?) = try XCTUnwrap(TestingData.SessionData.tooManyRequest())
            
            let data: Data = try XCTUnwrap(tooManyRequestTuple.data)
            let response: URLResponse = try XCTUnwrap(tooManyRequestTuple.response)
            
            // session publish 第一個 output
            if let firstOutputSubject = spyAPIKeySession.outputSubjects.first {
                firstOutputSubject.send((data, response))
                firstOutputSubject.send(completion: .finished)
            }
            else {
                XCTFail("arrange 失誤，第一次 subscribe `sut.publisher(for:)` 應該會給 subscribe spy api key session，進而產生一個 subject")
            }
            // session publish 第二個 output
            if spyAPIKeySession.outputSubjects.count >= 2 {
                let secondOutputSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = spyAPIKeySession.outputSubjects[1]
                secondOutputSubject.send((data, response))
                secondOutputSubject.send(completion: .finished)
            }
            else {
                XCTFail("arrange 失誤，第二次 subscribe `sut.publisher(for:)` 應該會給 subscribe spy api key session，進而產生第二個 subject")
            }
            
            // 現階段 fetcher 應該還沒 publish 任何 output
            XCTAssertNil(firstReceivedValue)
            XCTAssertNil(secondReceivedValue)
        }
        
        do {
            let latestRateTuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData.SessionData.latestRate()
            
            let data: Data = try XCTUnwrap(latestRateTuple.data)
            let response: URLResponse = try XCTUnwrap(latestRateTuple.response)
            
            // session publish 第三個 output
            if spyAPIKeySession.outputSubjects.count >= 3 {
                let thirdOutputSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = spyAPIKeySession.outputSubjects[2]
                thirdOutputSubject.send((data, response))
                thirdOutputSubject.send(completion: .finished)
            }
            else {
                XCTFail("arrange 失誤， spy api key session 針對 fetcher 第一次的 subscribe publish too many request 的 error，fetcher 換完 api key 後會重新 subscribe spy api key session，這時候應該要產生第三個 subject。")
            }
            
            // session publish 第四個 output
            if spyAPIKeySession.outputSubjects.count >= 4 {
                let fourthOutputSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = spyAPIKeySession.outputSubjects[3]
                fourthOutputSubject.send((data, response))
                fourthOutputSubject.send(completion: .finished)
            }
            else {
                XCTFail("arrange 失誤， spy api key session 針對 fetcher 第二次的 subscribe publish too many request 的 error，fetcher 換完 api key 後會重新 subscribe spy api key session，這時候應該要產生第四個 subject。")
            }
        }
        
        // assert
        if spyAPIKeySession.receivedAPIKeys.count == 4 {
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
        }
        else {
            XCTFail("spy api key session 應該要剛好收到 4 個 request")
        }
        
        do {
            XCTAssertNotNil(firstReceivedValue)
            
            let firstReceivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(firstReceivedCompletion)
            switch firstReceivedCompletion {
                case .finished:
                    break
                case .failure(let failure):
                    XCTFail("不應該收到錯誤卻收到\(failure)")
            }
        }
        
        do {
            XCTAssertNotNil(secondReceivedValue)
            
            let secondReceivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(secondReceivedCompletion)
            switch secondReceivedCompletion {
                case .finished:
                    break
                case .failure(let failure):
                    XCTFail("不應該收到錯誤卻收到\(failure)")
            }
        }
    }
}

// MARK: - private helper method
private extension FetcherTests {
    func sessionDataPublisher(_ tuple: (data: Data?, response: URLResponse?, error: Error?)) throws -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        if let urlError = tuple.error as? URLError {
            return Fail(error: urlError)
                .eraseToAnyPublisher()
        }
        else {
            let data: Data = try XCTUnwrap(tuple.data)
            let response: URLResponse = try XCTUnwrap(tuple.response)
            
            return Just((data: data, response: response))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - name space: test double
private extension FetcherTests {
    private class StubRateSession: RateSession {
        var outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError>!
        
        func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            outputPublisher
        }
    }
    
    class SpyRateSession: RateSession {
        // MARK: - initializer
        init() {
            receivedAPIKeys = []
            outputPublishers = []
        }
        
        // MARK: - instance properties
        private(set) var receivedAPIKeys: [String]
        
        var outputPublishers: [AnyPublisher<(data: Data, response: URLResponse), URLError>]
        
        // MARK: - instance method
        func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            if let apiKey = request.value(forHTTPHeaderField: "apikey") {
                receivedAPIKeys.append(apiKey)
            }
            
            if outputPublishers.isEmpty {
                return Empty()
                    .setFailureType(to: URLError.self)
                    .eraseToAnyPublisher()
            }
            else {
                return outputPublishers.removeFirst()
            }
        }
    }
    
    final class SpyAPIKeyRateSession: RateSession {
        // MARK: - initializer
        init() {
            receivedAPIKeys = []
            outputSubjects = []
        }
        
        // MARK: - instance properties
        private(set) var receivedAPIKeys: [String]
        
        private(set) var outputSubjects: [PassthroughSubject<(data: Data, response: URLResponse), URLError>]
        
        // MARK: - instance method
        func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
                receivedAPIKeys.append(receivedAPIKey)
            }
            
            let outputSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = PassthroughSubject<(data: Data, response: URLResponse), URLError>()
            outputSubjects.append(outputSubject)
            
            return outputSubject.eraseToAnyPublisher()
        }
    }
}
