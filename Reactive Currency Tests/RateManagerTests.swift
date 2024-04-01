import XCTest
import Combine
@testable import ReactiveCurrency

final class RateManagerTests: XCTestCase {
    private var sut: RateManager!
    
    private var historicalRateProvider: TestDouble.HistoricalRateProvider!
    private var latestRateProvider: TestDouble.LatestRateProvider!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        historicalRateProvider = TestDouble.HistoricalRateProvider()
        latestRateProvider = TestDouble.LatestRateProvider()
        
        sut = RateManager(historicalRateProvider: historicalRateProvider,
                          latestRateProvider: latestRateProvider)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateProvider = nil
        latestRateProvider = nil
        
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
    }
    
    func testAllSuccess() throws {
        // arrange
        let fakeHistoricalRateProvider: TestDouble.HistoricalRateProvider = historicalRateProvider
        let fakeLatestRateProvider: TestDouble.LatestRateProvider = latestRateProvider
        
        var receivedRateTuple: BaseRateManager.RateTuple?
        var receivedCompletion: Subscribers.Completion<Error>?
        let startDate: Date = Date(timeIntervalSince1970: 0)
        let numberOfDays: Int = 3
        let historicalRateDateStrings: Set<String> = sut.historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                                                                   from: startDate)
        
        // act
        sut
            .ratePublisher(numberOfDays: numberOfDays,
                           from: startDate)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rateTuple in receivedRateTuple = rateTuple })
            .store(in: &anyCancellableSet)
        
        do /*simulate historical rate provider's result*/ {
            try historicalRateDateStrings
                .forEach { historicalRateDateString in
                    let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: historicalRateDateString)
                    fakeHistoricalRateProvider.publish(dummyHistoricalRate, for: historicalRateDateString)
                    fakeHistoricalRateProvider.publish(completion: .finished, for: historicalRateDateString)
                }
        }
        
        do /*simulate latest rate provider's result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            fakeLatestRateProvider.publish(dummyLatestRate)
            fakeLatestRateProvider.publish(completion: .finished)
        }
        
        // assert
        do {
            let receivedRateTuple: BaseRateManager.RateTuple = try XCTUnwrap(receivedRateTuple)
            XCTAssertEqual(Set(receivedRateTuple.historicalRateSet.map { historicalRate in historicalRate.dateString }),
                           historicalRateDateStrings)
            
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            
            switch receivedCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive any failure but receive: \(failure)")
            }
        }
    }
}
