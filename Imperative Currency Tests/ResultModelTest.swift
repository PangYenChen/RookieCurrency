import XCTest
@testable import ImperativeCurrency

final class ResultModelTest: XCTestCase {
    // MARK: - system under test
    private var sut: ResultModel!
    
    // MARK: - test double
    private var userSettingManager: TestDouble.UserSettingManager!
    private var rateManager: TestDouble.RateManager!
    private var dummyCurrencyCodeDescriber: CurrencyDescriberProtocol!
    private var fakeTimer: TestDouble.Timer!
    
    override func setUp() {
        userSettingManager = TestDouble.UserSettingManager()
        rateManager = TestDouble.RateManager()
        dummyCurrencyCodeDescriber = TestDouble.CurrencyDescriber()
        fakeTimer = TestDouble.Timer()
        
        sut = ResultModel(userSettingManager: userSettingManager,
                          rateManager: rateManager,
                          currencyDescriber: dummyCurrencyCodeDescriber,
                          timer: fakeTimer)
    }
    
    override func tearDown() {
        sut = nil
        
        fakeTimer = nil
        dummyCurrencyCodeDescriber = nil
        rateManager = nil
        userSettingManager = nil
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
    
    func testAllSucceed() throws {
        // arrange
        let expectedNumberOfDays: Int = Int.random(in: 1...10)
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        userSettingManagerStub.numberOfDays = expectedNumberOfDays
        
        let rateManagerSpy: TestDouble.RateManager = rateManager
        
        var expectedRateStatics: [ResultModel.RateStatistic]?
        var expectedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var expectedRefreshStatus: ResultModel.RefreshStatus?
        var expectedError: Error?
        
        sut.rateStatisticsHandler = { rateStatics in expectedRateStatics = rateStatics }
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in
            expectedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet
        }
        sut.refreshStatusHandler = { refreshStatus in expectedRefreshStatus = refreshStatus }
        sut.errorHandler = { error in expectedError = error }
        
        // act
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertEqual(rateManagerSpy.numberOfDays, expectedNumberOfDays)
        
        XCTAssertNil(expectedRateStatics)
        XCTAssertNil(expectedDataAbsentCurrencyCodeSet)
        do {
            let expectedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(expectedRefreshStatus)
            switch expectedRefreshStatus {
                case .process: return
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(expectedError)
        
        // act
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            rateManagerSpy.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        do /*assert that expected rate statistics is empty*/ {
            let expectedRateStatics: [ResultModel.RateStatistic] = try XCTUnwrap(expectedRateStatics)
            XCTAssertFalse(expectedRateStatics.isEmpty)
        }
        XCTAssertNil(expectedDataAbsentCurrencyCodeSet)
        do /*assert expected refresh status is .idle*/ {
            let expectedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(expectedRefreshStatus)
            switch expectedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: return
            }
        }
        XCTAssertNil(expectedError)
    }
    
    func testRateManagerResultInError() throws {
        // arrange
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        let rateManagerStub: TestDouble.RateManager = rateManager
        
        var receivedRateStatics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        let expectedTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        sut.rateStatisticsHandler = { rateStatistics in receivedRateStatics = rateStatistics }
        
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
        
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
            
        sut.errorHandler = { error in receivedError = error }
        
        // act
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertNil(receivedRateStatics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let expectedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch expectedRefreshStatus {
                case .process: return
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        rateManagerStub.executeCompletionHandlerWith(result: .failure(expectedTimeoutError))
        
        // assert
        XCTAssertNil(receivedRateStatics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do /*assert received refresh status*/ {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: return
            }
        }
        
        do /*assert received error*/ {
            let receivedError: URLError = try XCTUnwrap(receivedError as? URLError)
            XCTAssertEqual(receivedError, expectedTimeoutError)
        }
    }
}
