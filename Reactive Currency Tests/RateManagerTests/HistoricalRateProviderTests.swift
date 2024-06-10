import XCTest
import Combine

@testable import ReactiveCurrency

final class HistoricalRateProviderRingTests: XCTestCase {
    private var sut: HistoricalRateProviderRing!
    
    private var historicalRateStorage: TestDouble.HistoricalRateStorage!
    private var nextHistoricalRateProvider: TestDouble.HistoricalRateProvider!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        historicalRateStorage = TestDouble.HistoricalRateStorage()
        nextHistoricalRateProvider = TestDouble.HistoricalRateProvider()
        
        sut = HistoricalRateProviderRing(storage: historicalRateStorage,
                                         nextProvider: nextHistoricalRateProvider)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        historicalRateStorage = nil
        nextHistoricalRateProvider = nil
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
    
    func testGetFromNextProviderAndThenGetFromStorageAndThenRemoveAllStorage() throws {
        // arrange
        var receivedRate: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        let dummyDateString: String = "1970-01-01"
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRatePublisherFor(dateString: dummyDateString, id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rate in receivedRate = rate })
            .store(in: &anyCancellableSet)
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        do {
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData
                .Instance
                .historicalRateFor(dateString: dummyDateString)
            nextHistoricalRateProvider.publish(dummyHistoricalRate, for: dummyDateString)
            
            nextHistoricalRateProvider.publish(completion: .finished, for: dummyDateString)
        }
        
        // assert
        XCTAssertNotNil(receivedRate)
        do {
            let receivedCompletion: Subscribers.Completion<any Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
        
        XCTAssertNotNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        // arrange
        receivedRate = nil
        
        // act
        sut.historicalRatePublisherFor(dateString: dummyDateString, id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rate in receivedRate = rate })
            .store(in: &anyCancellableSet)
        
        // assert
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        XCTAssertNotNil(receivedRate)
        do {
            let receivedCompletion: Subscribers.Completion<any Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
        
        // act
        sut.removeAllStorage()
        
        // assert
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
    }
    
    func testFailure() throws {
        // arrange
        var receivedRate: ResponseDataModel.HistoricalRate?
        var receivedCompletion: Subscribers.Completion<Error>?
        let dummyDateString: String = "1970-01-01"
        let expectedURLTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRatePublisherFor(dateString: dummyDateString, id: UUID().uuidString)
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { rate in receivedRate = rate })
            .store(in: &anyCancellableSet)
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
        
        nextHistoricalRateProvider.publish(completion: .failure(expectedURLTimeoutError), for: dummyDateString)
        
        // assert
        XCTAssertNil(receivedRate)
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: XCTFail("should not complete normally")
                case .failure(let failure): XCTAssertEqual(failure as? URLError, expectedURLTimeoutError)
            }
        }
        
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndSubjectDictionary[dummyDateString])
    }
}
