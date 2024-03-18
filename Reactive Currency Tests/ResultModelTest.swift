import XCTest
import Combine
@testable import ReactiveCurrency

class ResultModelTest: XCTestCase {
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        let userSettingManagerStub: UserSettingManagerProtocol
        let numberOfDays: Int = Int.random(in: 1...10)
        do {
            let dummyBaseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let dummyResultOrder: BaseResultModel.Order = .increasing
            let dummyCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD"]
            userSettingManagerStub = TestDouble.UserSettingManager(
                numberOfDays: numberOfDays,
                baseCurrencyCode: dummyBaseCurrencyCode,
                resultOrder: dummyResultOrder,
                currencyCodeOfInterest: dummyCurrencyCodeOfInterest
            )
        }
        
        let rateManagerSpy: TestDouble.RateManager
        do {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            rateManagerSpy = TestDouble.RateManager(result: dummyResult)
        }
        
        let timerSpy: TestDouble.Timer = TestDouble.Timer()
        
        // act
        let sut: ResultModel = ResultModel(userSettingManager: userSettingManagerStub,
                                           rateManager: rateManagerSpy,
                                           currencyDescriber: currencyDescriberStub,
                                           timer: timerSpy)
        
        sut.rateStatistics
            .subscribe(AnySubscriber())
        
        timerSpy.publish()
        
        // assert
        XCTAssertEqual(numberOfDays, rateManagerSpy.numberOfDays)
    }
}
