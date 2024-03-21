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
    
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let expectedNumberOfDays: Int = Int.random(in: 1...10)
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        userSettingManagerStub.numberOfDays = expectedNumberOfDays
        
        let rateManagerSpy: TestDouble.RateManager = rateManager
        
        // act
        fakeTimer.block?()
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            rateManagerSpy.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        XCTAssertEqual(rateManagerSpy.numberOfDays, expectedNumberOfDays)
    }
    
    func testAllSucceed() throws {
        // arrange
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
        fakeTimer.block?()
        
        // assert
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
            
            rateManager.executeCompletionHandlerWith(result: dummyResult)
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
}
