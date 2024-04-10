import XCTest
@testable import ImperativeCurrency

class HistoricalRateProviderRingTests: XCTestCase {
    private var sut: HistoricalRateProviderRing!
    
    private var historicalRateStorage: TestDouble.HistoricalRateStorage!
    private var nextHistoricalRateProvider: TestDouble.HistoricalRateProvider!
    
    private var receivedHistoricalRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
    
    override func setUp() {
        historicalRateStorage = TestDouble.HistoricalRateStorage(dateStringAndRateDirectory: [:])
        nextHistoricalRateProvider = TestDouble.HistoricalRateProvider()
        
        sut = HistoricalRateProviderRing(storage: historicalRateStorage,
                                         nextProvider: nextHistoricalRateProvider)
    }
    
    override func tearDown() {
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
    
    func testGetFromNextProvider() {
        // arrange, do nothing
        
        // act
        
        
    }
}
