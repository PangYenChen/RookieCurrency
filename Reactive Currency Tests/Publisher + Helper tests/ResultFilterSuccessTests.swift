import Combine
import XCTest
@testable import ReactiveCurrency

final class ResultFilterSuccessTests: XCTestCase {
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
        let expectedValue: Int = 3
        let expectedResult: Result<Int, Error> = .success(expectedValue)
        var receivedOutput: Int?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterSuccess()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { output in receivedOutput = output })
            .store(in: &anyCancellableSet)
        
        // act
        passthrough.send(expectedResult)
        
        // assert
        XCTAssertEqual(receivedOutput, expectedValue)
        XCTAssertNil(receivedCompletion)
    }
    
    func testFailure() {
        // arrange
        let expectedError: URLError = URLError(URLError.Code.timedOut)
        let expectedResult: Result<Int, Error> = .failure(expectedError)
        var receivedOutput: Int?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterSuccess()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { output in receivedOutput = output })
            .store(in: &anyCancellableSet)
        
        // act
        passthrough.send(expectedResult)
        
        // assert
        XCTAssertNil(receivedOutput)
        XCTAssertNil(receivedCompletion)
    }
    
    func testFinished() {
        // arrange
        var receivedOutput: Int?
        var receivedCompletion: Subscribers.Completion<Never>?
        
        passthrough
            .resultFilterSuccess()
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
