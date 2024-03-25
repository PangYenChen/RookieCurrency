import XCTest
import Combine
@testable import ReactiveCurrency

class ResultModelTest: XCTestCase {
    private var anyCancellableSet: Set<AnyCancellable> = Set<AnyCancellable>()
    
    func testNoRetainCycleOccur() {
        // arrange
        var sut: ResultModel?
        do /*set up sut*/ {
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
        let expectedNumberOfDays: Int = Int.random(in: 1...10)
        let userSettingManagerStub: TestDouble.UserSettingManager = TestDouble.UserSettingManager()
        userSettingManagerStub.numberOfDays = expectedNumberOfDays
        
        let rateManagerSpy: TestDouble.RateManager = TestDouble.RateManager()
        let fakeTimer: TestDouble.Timer = TestDouble.Timer()
        
        let sut: ResultModel
        do /*initialize sut*/ {
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            sut = ResultModel(userSettingManager: userSettingManagerStub,
                              rateManager: rateManagerSpy,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: fakeTimer)
        }
        
        var expectedRateStatics: [ResultModel.RateStatistic]?
        var expectedDataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>?
        var expectedRefreshStatus: ResultModel.RefreshStatus?
        var expectedError: Error?
        
        sut.rateStatistics
            .sink { rateStatistics in expectedRateStatics = rateStatistics }
            .store(in: &anyCancellableSet)
        
        sut.dataAbsentCurrencyCodeSet
            .sink { dataAbsentCurrencyCodeSet in expectedDataAbsentCurrencyCodeSet = dataAbsentCurrencyCodeSet }
            .store(in: &anyCancellableSet)
        
        sut.refreshStatus
            .sink { refreshStatus in expectedRefreshStatus = refreshStatus }
            .store(in: &anyCancellableSet)
        
        sut.error
            .sink { error in expectedError = error }
            .store(in: &anyCancellableSet)
        
        // act
        fakeTimer.publish()

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
            let dummyOutput: BaseRateManager.RateTuple = (latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate])
            
            rateManagerSpy.publish(dummyOutput)
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
