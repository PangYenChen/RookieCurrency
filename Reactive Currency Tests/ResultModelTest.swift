import XCTest
import Combine
@testable import ReactiveCurrency

class ResultModelTest: XCTestCase {
    private var anyCancellableSet: Set<AnyCancellable> = Set<AnyCancellable>()
    
    func testNoRetainCycleOccur() {
        // arrange
        var sut: ResultModel?
        do /*initialize sut*/ {
            let dummyUserSettingManager: UserSettingManagerProtocol = TestDouble.UserSettingManager()
            let dummyRateManager: RateManagerProtocol = TestDouble.RateManager()
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            let dummyTimer: TimerProtocol = TestDouble.Timer()
            
            sut = ResultModel(userSettingManager: dummyUserSettingManager,
                              rateManager: dummyRateManager,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: dummyTimer)
        }
        
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
        let userSettingManagerStub: TestDouble.UserSettingManager = TestDouble.UserSettingManager()
        userSettingManagerStub.numberOfDays = receivedNumberOfDays
        
        let fakeRateManager: TestDouble.RateManager = TestDouble.RateManager()
        let fakeTimer: TestDouble.Timer = TestDouble.Timer()
        
        let sut: ResultModel
        do /*initialize sut*/ {
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            sut = ResultModel(userSettingManager: userSettingManagerStub,
                              rateManager: fakeRateManager,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: fakeTimer)
        }
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        sut.rateStatistics
            .sink { rateStatistics in receivedRateStatistics = rateStatistics }
            .store(in: &anyCancellableSet)
        
        sut.dataAbsentCurrencyCodeSet
            .sink { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
            .store(in: &anyCancellableSet)
        
        sut.refreshStatus
            .sink { refreshStatus in receivedRefreshStatus = refreshStatus }
            .store(in: &anyCancellableSet)
        
        sut.error
            .sink { error in receivedError = error }
            .store(in: &anyCancellableSet)
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.publish()

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
            let dummyOutput: BaseRateManager.RateTuple = (latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate])
            
            fakeRateManager.publish(dummyOutput)
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
        let userSettingManagerStub: TestDouble.UserSettingManager = TestDouble.UserSettingManager()
        
        let fakeRateManager: TestDouble.RateManager = TestDouble.RateManager()
        let fakeTimer: TestDouble.Timer = TestDouble.Timer()
        
        let sut: ResultModel
        do /*initialize sut*/ {
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            sut = ResultModel(userSettingManager: userSettingManagerStub,
                              rateManager: fakeRateManager,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: fakeTimer)
        }
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        let receivedTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        sut.rateStatistics
            .sink { rateStatistics in receivedRateStatistics = rateStatistics }
            .store(in: &anyCancellableSet)
        
        sut.dataAbsentCurrencyCodeSet
            .sink { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
            .store(in: &anyCancellableSet)
        
        sut.refreshStatus
            .sink { refreshStatus in receivedRefreshStatus = refreshStatus }
            .store(in: &anyCancellableSet)
        
        sut.error
            .sink { error in receivedError = error }
            .store(in: &anyCancellableSet)
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.publish()
        
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
        fakeRateManager.publish(completion: .failure(receivedTimeoutError))
        
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
        let userSettingManagerStub: TestDouble.UserSettingManager = TestDouble.UserSettingManager()
        let currencyCodeInResponseOfLatestAndHistoricalRate: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let currencyCodeNotInHistoricalRate: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInLatestRate"
        let currencyCodeNotInLatestRate: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInHistoricalRate"
        userSettingManagerStub.currencyCodeOfInterest = currencyCodeInResponseOfLatestAndHistoricalRate.union([currencyCodeNotInHistoricalRate, currencyCodeNotInLatestRate])
        
        let fakeRateManager: TestDouble.RateManager = TestDouble.RateManager()
        
        let fakeTimer: TestDouble.Timer = TestDouble.Timer()
        
        let sut: ResultModel
        do /*initialize sut*/ {
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            sut = ResultModel(userSettingManager: userSettingManagerStub,
                              rateManager: fakeRateManager,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: fakeTimer)
        }
        
        var receivedRateStatistics: [ResultModel.RateStatistic]?
        var receivedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var receivedRefreshStatus: ResultModel.RefreshStatus?
        var receivedError: Error?
        
        sut.rateStatistics
            .sink { rateStatistics in receivedRateStatistics = rateStatistics }
            .store(in: &anyCancellableSet)
        
        sut.dataAbsentCurrencyCodeSet
            .sink { dataAbsentCurrencyCodeSet in receivedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
            .store(in: &anyCancellableSet)
        
        sut.refreshStatus
            .sink { refreshStatus in receivedRefreshStatus = refreshStatus }
            .store(in: &anyCancellableSet)
        
        sut.error
            .sink { error in receivedError = error }
            .store(in: &anyCancellableSet)
        
        // act
        sut.resumeAutoRefresh()
        fakeTimer.publish()
        
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
            
            fakeRateManager.publish((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
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
