import XCTest
import Combine
@testable import ReactiveCurrency

final class RateManagerTests: XCTestCase {
    // TODO: "`RateManager` 的 method 太長了，不好測試。等 method 拆解好之後再來寫測試。
    
    private var sut: RateManager!
    
    private var anyCancellableSet: Set<AnyCancellable> = []
    
    override func tearDown() {
        sut = nil
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = Set<AnyCancellable>()
    }
    
//    func testNoCacheAndDiskData() throws {
//        // arrange
//        let stubFetcher = StubFetcher()
//        let spyArchiver = TestDouble.SpyArchiver.self
//        sut = RateManager(fetcher: stubFetcher, archiver: spyArchiver)
//        
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        var receivedCompletion: Subscribers.Completion<Error>?
//        var receivedHistoricalRateSet: Set<ResponseDataModel.HistoricalRate>?
//        
//        // act
//        sut
//            .ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate)
//            .sink(
//                receiveCompletion: { completion in receivedCompletion = completion },
//                receiveValue: { _, historicalRateSet in receivedHistoricalRateSet = historicalRateSet }
//            )
//            .store(in: &anyCancellableSet)
//        
//        // assert
//        sut.concurrentQueue.sync {
//            XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//            XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//            XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
//            XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//        }
//        
//        do {
//            switch receivedCompletion {
//            case .finished           : break
//            case .failure(let error) : XCTFail("should not receive any failure but receive : \(error)")
//            case .none               : XCTFail("should receive a completion.")
//            }
//        }
//        
//        do {
//            XCTAssertEqual(receivedHistoricalRateSet?.count, numberOfDays)
//        }
//    }
//    
//    func testAllFromCache() throws {
//        // arrange
//        let stubFetcher = StubFetcher()
//        let spyArchiver = TestDouble.SpyArchiver.self
//        sut = RateManager(fetcher: stubFetcher, archiver: spyArchiver)
//        
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        var receivedCompletion: Subscribers.Completion<Error>?
//        var receivedHistoricalRateSet: Set<ResponseDataModel.HistoricalRate>?
//        
//        // act
//        sut.ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate)
//            .flatMap { [unowned self] _ in sut.ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate) }
//            .sink(
//                receiveCompletion: { completion in receivedCompletion = completion },
//                receiveValue: { _, historicalRateSet in receivedHistoricalRateSet = historicalRateSet }
//            )
//            .store(in: &anyCancellableSet)
//        
//        // assert
//        do {
//            switch receivedCompletion {
//            case .finished           : break
//            case .failure(let error) : XCTFail("should not receive any failure but receive : \(error)")
//            case .none               : XCTFail("should receive a completion.")
//            }
//        }
//        
//        do {
//            XCTAssertEqual(receivedHistoricalRateSet?.count, numberOfDays)
//        }
//        
//        XCTAssertEqual(receivedHistoricalRateSet?.count, numberOfDays)
//        
//        sut.concurrentQueue.sync {
//            XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//            XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//            XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
//            XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//        }
//    }
}

// MARK: - name space: test double
extension RateManagerTests {
    final class StubFetcher: FetcherProtocol {
        private(set) var numberOfLatestEndpointCall: Int = 0
        
        private(set) var dateStringOfHistoricalEndpointCall: Set<String> = []
        
        func publisher<Endpoint>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint: EndpointProtocol {
            if endpoint.url.path.contains("latest") {
                do {
                    let latestRate: Endpoint.ResponseType = try XCTUnwrap(TestingData.Instance.latestRate() as? Endpoint.ResponseType)
                    numberOfLatestEndpointCall += 1
                    
                    return Just(latestRate)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            else {
                let dateString: String = endpoint.url.lastPathComponent
                do {
                    if AppUtility.requestDateFormatter.date(from: dateString) != nil,
                       let historicalRate = try TestingData.Instance.historicalRateFor(dateString: dateString) as? Endpoint.ResponseType {
                        dateStringOfHistoricalEndpointCall.insert(dateString)
                        
                        return Just(historicalRate)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
                catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            
            // the following should be dead code, which purely make compiler silent
            return Fail(error: Fetcher.Error.unknownError)
                .eraseToAnyPublisher()
        }
    }
}
