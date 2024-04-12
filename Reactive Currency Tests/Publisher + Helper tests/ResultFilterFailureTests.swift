import Combine
import XCTest
@testable import ReactiveCurrency

final class ResultFilterFailureTests: XCTestCase {
    private var passthrough: PassthroughSubject<Result<Int, Error>, Never>!
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        anyCancellableSet = Set<AnyCancellable>()
        
        passthrough = PassthroughSubject<Result<Int, Error>, Never>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        passthrough = nil
    }
    
    func testSuccess() {
        // arrange
        let dummyValue: Int = 3
        let dummyResult: Result<Int, Error> = .success(dummyValue)
        var receivedOutput: Error?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterFailure()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { output in receivedOutput = output })
            .store(in: &anyCancellableSet)
        
        // act
        passthrough.send(dummyResult)
        
        // assert
        XCTAssertNil(receivedOutput)
        XCTAssertNil(receivedCompletion)
    }
    
    func testFailure() {
        // arrange
        let expectedError: URLError = URLError(URLError.Code.timedOut)
        let expectedResult: Result<Int, Error> = .failure(expectedError)
        var receivedOutput: Error?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterFailure()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { output in receivedOutput = output })
            .store(in: &anyCancellableSet)
        
        // act
        passthrough.send(expectedResult)
        
        // assert
        XCTAssertEqual(receivedOutput as? URLError, expectedError)
        XCTAssertNil(receivedCompletion)
    }
    
    func testFinished() {
        // arrange
        var receivedOutput: Error?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterFailure()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { output in receivedOutput = output })
            .store(in: &anyCancellableSet)
        
        // act
        passthrough.send(completion: .finished)
        
        // assert
        XCTAssertNil(receivedOutput)
        XCTAssertNotNil(receivedCompletion)
    }
}
