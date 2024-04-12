import Combine
import XCTest
@testable import ReactiveCurrency

final class WithLatestFromTests: XCTestCase {
    private var upstream: PassthroughSubject<Int, Never>!
    private var other: PassthroughSubject<String, Never>!
    
    var receivedInt: Int?
    var receivedString: String?
    var receivedCompletion: Subscribers.Completion<Never>?
    
    private var anyCancellableSet: Set<AnyCancellable>!

    override func setUp() {
        upstream = PassthroughSubject<Int, Never>()
        other = PassthroughSubject<String, Never>()
        
        anyCancellableSet = Set<AnyCancellable>()
        
        upstream
            .withLatestFrom(other)
            .sink(receiveCompletion: { [unowned self] completion in receivedCompletion = completion},
                  receiveValue: { [unowned self] int, string in receivedInt = int; receivedString = string })
            .store(in: &anyCancellableSet)
        
        removeAllReceivedValue()
    }

    override func tearDown() {
        removeAllReceivedValue()
        
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        upstream = nil
        other = nil
    }
    
    func testSuccess() {
        do {
            // arrange
            let dummyInt: Int = 1
            
            // act
            upstream.send(dummyInt)
            
            // assert
            assert()
        }
        
        // arrange
        let expectedString: String = "a"
        do {
            // act
            other.send(expectedString)
            
            // assert
            assert()
        }

        // arrange
        let expectedInt: Int = 2
        do {
            // act
            upstream.send(expectedInt)
            
            // assert
            assert(expectedInt: expectedInt,
                   expectedString: expectedString)
        }
        
        do {
            // arrange
            let dummyString: String = "b"
            
            // act
            other.send(dummyString)
            
            // assert
            assert(expectedInt: expectedInt,
                   expectedString: expectedString)
        }
    }
}

private extension WithLatestFromTests {
    func removeAllReceivedValue() {
        receivedInt = nil
        receivedString = nil
        receivedCompletion = nil
    }
    
    func assert(expectedInt: Int? = nil,
                expectedString: String? = nil,
                expectedCompletion: Subscribers.Completion<Never>? = nil) {
        XCTAssertEqual(expectedInt, receivedInt)
        XCTAssertEqual(expectedString, receivedString)
        XCTAssertEqual(expectedCompletion, receivedCompletion)
    }
}
