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
        let receivedNumberOfDays: Int = Int.random(in: 1...10)
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        userSettingManagerStub.numberOfDays = receivedNumberOfDays
        
        let rateManagerSpy: TestDouble.RateManager = rateManager
        
        var receivedRateStatics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        sut.rateStatisticsHandler = { rateStatics in receivedRateStatics = rateStatics }
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in
            receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet
        }
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
        sut.errorHandler = { error in receivedError = error }
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertEqual(rateManagerSpy.numberOfDays, receivedNumberOfDays)
        
        XCTAssertNil(receivedRateStatics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: return
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            rateManagerSpy.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        do /*assert that received rate statistics is empty*/ {
            let receivedRateStatics: [ResultModel.RateStatistic] = try XCTUnwrap(receivedRateStatics)
            
            XCTAssertEqual(userSettingManagerStub.currencyCodeOfInterest,
                           Set(receivedRateStatics.map { $0.currencyCode }))
        }
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do /*assert received refresh status is .idle*/ {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: return
            }
        }
        XCTAssertNil(receivedError)
    }
    
    func testRateManagerResultInError() throws {
        // arrange
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        let rateManagerStub: TestDouble.RateManager = rateManager
        
        var receivedRateStatics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        let receivedTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        sut.rateStatisticsHandler = { rateStatistics in receivedRateStatics = rateStatistics }
        
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
        
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
            
        sut.errorHandler = { error in receivedError = error }
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertNil(receivedRateStatics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: return
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        rateManagerStub.executeCompletionHandlerWith(result: .failure(receivedTimeoutError))
        
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
            XCTAssertEqual(receivedError, receivedTimeoutError)
        }
    }
}
