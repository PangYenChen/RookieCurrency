import XCTest
import Combine

@testable import ReactiveCurrency

final class HistoricalRateProviderTests: XCTestCase {
    private var sut: HistoricalRateProviderChain!
    
    private var historicalRateProviderSpy: TestDouble.HistoricalRateProvider!
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        historicalRateProviderSpy = TestDouble.HistoricalRateProvider()
        
        sut = HistoricalRateProviderChain(nextHistoricalRateProvider: historicalRateProviderSpy)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateProviderSpy = nil
        
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
    }
    
    func testPassingSuccess() throws {
        // arrange
        var receivedRate: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        let dateString: String = "1970-01-01"
        let expectedRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dateString)
        
        sut.publisherFor(dateString: dateString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rate in receivedRate = rate })
            .store(in: &anyCancellableSet)
            
        // act
        historicalRateProviderSpy.publish(expectedRate, for: dateString)
        historicalRateProviderSpy.publish(completion: .finished, for: dateString)
        
        // assert
        do /*assertion about received rate*/ {
            let receivedRate: ResponseDataModel.HistoricalRate = try XCTUnwrap(receivedRate)
            XCTAssertEqual(receivedRate, expectedRate)
        }
        
        do /*assertion about received error*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: break
                case .failure(let receivedFailure): XCTFail("should not receive failure, but receive: \(receivedFailure)")
            }
        }
    }
    
    func testPassingFailure() throws {
        // arrange
        var receivedRate: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        let dateString: String = "1970-01-01"
        let expectedTimeOut: URLError = URLError(URLError.Code.timedOut)
        
        sut.publisherFor(dateString: dateString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rate in receivedRate = rate })
            .store(in: &anyCancellableSet)
        
        // act
        historicalRateProviderSpy.publish(completion: .failure(expectedTimeOut), for: dateString)
        
        // assert
        do /*assertion about received rate*/ {
            XCTAssertNil(receivedRate)
        }
        
        do /*assertion about received error*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: XCTFail("should not complete normally")
                case .failure(let receivedFailure): XCTAssertEqual(receivedFailure as? URLError, expectedTimeOut)
            }
        }
    }
    
    func testRemoveCachedAndStoredRate() {
        // arrange, do nothing
        
        // act
        sut.removeCachedAndStoredRate()
        
        // assert
        XCTAssertEqual(historicalRateProviderSpy.numberOfCallOfRemoveCachedAndStoredRate, 1)
    }
}
