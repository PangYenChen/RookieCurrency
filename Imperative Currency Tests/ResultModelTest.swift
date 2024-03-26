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
        
        let fakeRateManager: TestDouble.RateManager = rateManager
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        sut.rateStatisticsHandler = { rateStatistics in receivedRateStatistics = rateStatistics }
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in
            receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet
        }
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
        sut.errorHandler = { error in receivedError = error }
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertEqual(fakeRateManager.numberOfDays, receivedNumberOfDays)
        
        XCTAssertNil(receivedRateStatistics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: break
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            fakeRateManager.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        do /*assert received rate statistics*/ {
            let receivedRateStatistics: [ResultModel.RateStatistic] = try XCTUnwrap(receivedRateStatistics)
            
            XCTAssertEqual(userSettingManagerStub.currencyCodeOfInterest,
                           Set(receivedRateStatistics.map { $0.currencyCode }))
        }
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do /*assert received refresh status is .idle*/ {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: break
            }
        }
        XCTAssertNil(receivedError)
    }
    
    func testRateManagerResultInError() throws {
        // arrange
        let fakeRateManager: TestDouble.RateManager = rateManager
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        let receivedTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        sut.rateStatisticsHandler = { rateStatistics in receivedRateStatistics = rateStatistics }
        
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
        
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
            
        sut.errorHandler = { error in receivedError = error }
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertNil(receivedRateStatistics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: break
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        fakeRateManager.executeCompletionHandlerWith(result: .failure(receivedTimeoutError))
        
        // assert
        XCTAssertNil(receivedRateStatistics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do /*assert received refresh status*/ {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: break
            }
        }
        
        do /*assert received error*/ {
            let receivedError: URLError = try XCTUnwrap(receivedError as? URLError)
            XCTAssertEqual(receivedError, receivedTimeoutError)
        }
    }
    
    func testDataAbsent() throws {
        // arrange
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        let currencyCodeInResponseOfLatestAndHistoricalRate: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let currencyCodeNotInHistoricalRate: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInLatestRate"
        let currencyCodeNotInLatestRate: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInHistoricalRate"
        userSettingManagerStub.currencyCodeOfInterest = currencyCodeInResponseOfLatestAndHistoricalRate.union([currencyCodeNotInHistoricalRate, currencyCodeNotInLatestRate])
        
        let fakeRateManager: TestDouble.RateManager = rateManager
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        sut.rateStatisticsHandler = { rateStatistics in receivedRateStatistics = rateStatistics }
        
        sut.dataAbsentCurrencyCodeSetHandler = { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
        
        sut.refreshStatusHandler = { refreshStatus in receivedRefreshStatus = refreshStatus }
        
        sut.errorHandler = { error in receivedError = error }
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.executeBlock()
        
        // assert
        XCTAssertNil(receivedRateStatistics)
        XCTAssertNil(receivedDataAbsentCurrencyCodeSet)
        do {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: break
                case .idle: XCTFail("It should be .process")
            }
        }
        XCTAssertNil(receivedError)
        
        // act
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            fakeRateManager.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        do /*assert received rate statistics*/ {
            let receivedRateStatistics: [ResultModel.RateStatistic] = try XCTUnwrap(receivedRateStatistics)
            XCTAssertEqual(currencyCodeInResponseOfLatestAndHistoricalRate,
                           Set(receivedRateStatistics.map { $0.currencyCode }))
        }
        do /*assert received data absent currency code set*/ {
            let receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = try XCTUnwrap(receivedDataAbsentCurrencyCodeSet)
            XCTAssertEqual(receivedDataAbsentCurrencyCodeSet,
                           [currencyCodeNotInHistoricalRate, currencyCodeNotInLatestRate])
        }
        do /*assert received refresh status*/ {
            let receivedRefreshStatus: ResultModel.RefreshStatus = try XCTUnwrap(receivedRefreshStatus)
            switch receivedRefreshStatus {
                case .process: XCTFail("It should be .idle")
                case .idle: break
            }
        }
        XCTAssertNil(receivedError)
    }
}
