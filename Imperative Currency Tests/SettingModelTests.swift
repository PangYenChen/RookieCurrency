import XCTest

@testable import ImperativeCurrency

final class SettingModelTests: XCTestCase {
    private var sut: SettingModel!
    
    private var dummySetting: BaseResultModel.Setting!
    private var dummyCurrencyDescriber: CurrencyDescriberProtocol!
    
    private var receivedBaseCurrencyCodeDidChange: Void?
    private var receivedCurrencyCodeOfInterestDidChange: Void?
    private var receivedHasModificationsToSave: Bool?
    
    private var receivedSetting: BaseResultModel.Setting?
    private var receivedCancel: Void?
    
    override func setUp() {
        dummySetting = (numberOfDays: 3,
                        baseCurrencyCode: "TWD",
                        currencyCodeOfInterest: ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"])
        
        dummyCurrencyDescriber = TestDouble.CurrencyDescriber()
        
        sut = SettingModel(setting: dummySetting,
                           saveCompletionHandler: { [unowned self] setting in receivedSetting = setting },
                           cancelCompletionHandler: { [unowned self] in receivedCancel = () },
                           currencyDescriber: dummyCurrencyDescriber)
        
        sut.baseCurrencyCodeDidChangeHandler = { [unowned self] in receivedBaseCurrencyCodeDidChange = () }
        sut.currencyCodeOfInterestDidChangeHandler = { [unowned self] in receivedCurrencyCodeOfInterestDidChange = () }
        sut.hasModificationsToSaveHandler = { [unowned self] hasModificationsToSave in receivedHasModificationsToSave = hasModificationsToSave }
    }
    
    override func tearDown() {
        sut = nil
        
        dummyCurrencyDescriber = nil
        dummySetting = nil
        removeAllReceivedValue()
    }
    
    func testNumberOfDaysChanges() throws {
        // arrange is done in `setUp`
        
        // act
        sut.numberOfDays = 4
        
        // assert
        assert(expectedHasModificationsToSave: true,
               expectedNumberOfDays: 4)
        
        // arrange
        removeAllReceivedValue()
        
        // act
        sut.numberOfDays = 3
        
        // assert
        assert(expectedHasModificationsToSave: false,
               expectedNumberOfDays: 3)
    }
    
    func testSave() throws {
        // arrange
        let expectedNumberOfDays: Int = 4
        
        // act
        sut.numberOfDays = expectedNumberOfDays
        sut.save()
        
        // assert
        do {
            var expectedSetting: BaseResultModel.Setting = dummySetting
            expectedSetting.numberOfDays = expectedNumberOfDays
            assert(expectedHasModificationsToSave: true,
                   expectedSetting: expectedSetting,
                   expectedNumberOfDays: expectedNumberOfDays)
        }
    }
    
    func testCancelWithoutModificationToSave() throws {
        // arrange is done in `setUp`
        
        // act
        sut.cancel()
        
        // assert
        assert(expectedCancel: (),
               expectedNumberOfDays: dummySetting.numberOfDays)
    }
    
    func testCancelWithModificationToSave() throws {
        // arrange
        let expectedNumberOfDays: Int = 4
        
        // act
        sut.numberOfDays = expectedNumberOfDays
        sut.cancel()
        
        // assert
        assert(expectedHasModificationsToSave: true,
               expectedCancel: (),
               expectedNumberOfDays: expectedNumberOfDays)
    }
}

// MARK: - private method
private extension SettingModelTests {
    func removeAllReceivedValue() {
        receivedBaseCurrencyCodeDidChange = nil
        receivedCurrencyCodeOfInterestDidChange = nil
        receivedHasModificationsToSave = nil
        
        receivedSetting = nil
        receivedCancel = nil
    }
    
    func assert(expectedBaseCurrencyCodeDidChange: Void? = nil,
                expectedCurrencyCodeOfInterestDidChange: Void? = nil,
                expectedHasModificationsToSave: Bool? = nil,
                expectedSetting: BaseResultModel.Setting? = nil,
                expectedCancel: Void? = nil,
                expectedNumberOfDays: Int) {
        if expectedBaseCurrencyCodeDidChange == nil {
            XCTAssertNil(receivedBaseCurrencyCodeDidChange)
        }
        else {
            XCTAssertNotNil(receivedBaseCurrencyCodeDidChange)
        }
        
        if expectedCurrencyCodeOfInterestDidChange == nil {
            XCTAssertNil(receivedCurrencyCodeOfInterestDidChange)
        }
        else {
            XCTAssertNotNil(receivedCurrencyCodeOfInterestDidChange)
        }
        
        XCTAssertEqual(expectedHasModificationsToSave, receivedHasModificationsToSave)
        
        if let expectedSetting {
            XCTAssertEqual(expectedSetting.numberOfDays, receivedSetting?.numberOfDays)
            XCTAssertEqual(expectedSetting.baseCurrencyCode, receivedSetting?.baseCurrencyCode)
            XCTAssertEqual(expectedSetting.currencyCodeOfInterest, receivedSetting?.currencyCodeOfInterest)
        }
        else {
            XCTAssertNil(receivedSetting)
        }
        
        if expectedCancel == nil {
            XCTAssertNil(receivedCancel)
        }
        else {
            XCTAssertNotNil(receivedCancel)
        }
        
        XCTAssertEqual(expectedNumberOfDays, sut.numberOfDays)
    }
}
