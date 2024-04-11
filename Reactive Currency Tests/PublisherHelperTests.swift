import XCTest
import Combine
@testable import ReactiveCurrency

final class PublisherHelperTests: XCTestCase {
    private var passthroughSubject: PassthroughSubject<Int, Error>!
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        passthroughSubject = PassthroughSubject<Int, Error>()
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet.removeAll()
        anyCancellableSet = nil
        
        passthroughSubject = nil
    }
    
    func testConvertOutputToResultSuccess() throws {
        // arrange
        var receivedResult: Result<Int, Error>?
        var receivedCompletion: Subscribers.Completion<Never>?
        let expectedValue: Int = 3
        
        passthroughSubject
            .convertOutputToResult()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { result in receivedResult = result })
            .store(in: &anyCancellableSet)
        
        // act
        passthroughSubject.send(expectedValue)
        
        // arrange
        try XCTAssertEqual(XCTUnwrap(receivedResult).get(), expectedValue)
        XCTAssertNil(receivedCompletion)
    }
    
    func testConvertOutputToResultFinished() throws {
        // arrange
        var receivedResult: Result<Int, Error>?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthroughSubject
            .convertOutputToResult()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { result in receivedResult = result })
            .store(in: &anyCancellableSet)
        
        // act
        passthroughSubject.send(completion: .finished)
        
        // arrange
        XCTAssertNil(receivedResult)
        XCTAssertNotNil(receivedCompletion)
    }
    
    func testConvertOutputToResultFailure() throws {
        // arrange
        var receivedResult: Result<Int, Error>?
        var receivedCompletion: Subscribers.Completion<Never>?
        let expectedError: URLError = URLError(URLError.Code.timedOut)
        
        passthroughSubject
            .convertOutputToResult()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { result in receivedResult = result })
            .store(in: &anyCancellableSet)
        
        // act
        passthroughSubject.send(completion: .failure(expectedError))
        
        // arrange
        do {
            let receivedResult: Result<Int, Error> = try XCTUnwrap(receivedResult)
            switch receivedResult {
                case .success(let receivedValue):
                    XCTFail("should not receive value, but receive: \(receivedValue)")
                    
                case .failure(let error):
                    guard let urlError = error as? URLError else {
                        XCTFail("should receive url error but receive: \(error)")
                        return
                    }
                    guard urlError == expectedError else {
                        XCTFail("should receive timeout but receive: \(urlError)")
                        return
                    }
            }
        }
        
        XCTAssertNotNil(receivedCompletion)
    }
}
