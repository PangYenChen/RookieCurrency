import XCTest
@testable import ImperativeCurrency

final class ResultModelTest: XCTestCase {
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        
        let userSettingManagerStub: UserSettingManagerProtocol
        let numberOfDays: Int = Int.random(in: 1...10)
        do {
            let dummyBaseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let dummyResultOrder: QuasiBaseResultModel.Order = .increasing
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
        
        let dummyCurrencyDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        let timerSpy: TestDouble.Timer = TestDouble.Timer()
        
        // act
        let sut: ResultModel = ResultModel(rateManager: rateManagerSpy,
                                           userSettingManager: userSettingManagerStub,
                                           currencyDescriber: dummyCurrencyDescriber,
                                           timer: timerSpy)
        
        timerSpy.block?()
        
        // assert
        XCTAssertEqual(numberOfDays, rateManagerSpy.numberOfDays)
    }
}
