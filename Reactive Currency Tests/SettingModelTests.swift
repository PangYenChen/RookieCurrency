import XCTest
import Combine

@testable import ReactiveCurrency

final class SettingModelTests: XCTestCase {
    private var sut: SettingModel!
    
    private var dummySetting: BaseResultModel.Setting!
    private var dummyCurrencyDescriber: CurrencyDescriberProtocol!
    
    private var receivedNumberOfDaysDidChange: Void?
    private var receivedBaseCurrencyCodeDidChange: Void?
    private var receivedCurrencyCodeOfInterestDidChange: Void?
    private var receivedHasModificationsToSave: Bool?
    private var receivedCancellationNeedsToBeConfirmed: Bool?
    
    private var receivedSetting: BaseResultModel.Setting?
    private var receivedCancel: Void?
        
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        dummySetting = (numberOfDays: 3,
                        baseCurrencyCode: "TWD",
                        currencyCodeOfInterest: ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"])
        let saveSettingSubject: PassthroughSubject<BaseResultModel.Setting, Never> = PassthroughSubject<BaseResultModel.Setting, Never>()
        let cancelSubject: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>()
        dummyCurrencyDescriber = TestDouble.CurrencyDescriber()
        
        sut = SettingModel(setting: dummySetting,
                           saveSettingSubscriber: AnySubscriber(saveSettingSubject),
                           cancelSubscriber: AnySubscriber(cancelSubject),
                           currencyDescriber: dummyCurrencyDescriber)
        
        anyCancellableSet = Set<AnyCancellable>()
        
        saveSettingSubject
            .sink { [unowned self] setting in receivedSetting = setting }
            .store(in: &anyCancellableSet)
        
        cancelSubject
            .sink { [unowned self] cancel in receivedCancel = cancel }
            .store(in: &anyCancellableSet)
        
        sut.numberOfDaysDidChange
            .sink { [unowned self] numberOfDaysDidChange in receivedNumberOfDaysDidChange = numberOfDaysDidChange }
            .store(in: &anyCancellableSet)
        
        sut.baseCurrencyCodeDidChange
            .sink { [unowned self] baseCurrencyCodeDidChange in receivedBaseCurrencyCodeDidChange = baseCurrencyCodeDidChange }
            .store(in: &anyCancellableSet)
        
        sut.currencyCodeOfInterestDidChange
            .sink { [unowned self] currencyCodeOfInterestDidChange in receivedCurrencyCodeOfInterestDidChange = currencyCodeOfInterestDidChange }
            .store(in: &anyCancellableSet)
        
        sut.hasModificationsToSave
            .sink { [unowned self] hasModificationsToSave in receivedHasModificationsToSave = hasModificationsToSave }
            .store(in: &anyCancellableSet)
        
        sut.cancellationNeedsToBeConfirmed
            .sink { [unowned self] cancellationNeedsToBeConfirmed in receivedCancellationNeedsToBeConfirmed = cancellationNeedsToBeConfirmed }
            .store(in: &anyCancellableSet)
    }

    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        dummyCurrencyDescriber = nil
        dummySetting = nil
        removeAllReceivedValue()
    }
    
    func testNumberOfDaysChanges() throws {
        // arrange is done in `setUp`

        // act
        sut.set(numberOfDays: 4)
        
        // assert
        assert(expectedNumberOfDaysDidChange: (),
               expectedHasModificationsToSave: true,
               expectedNumberOfDays: 4)
        
        // arrange
        removeAllReceivedValue()
        
        // act
        sut.set(numberOfDays: 3)
        
        // assert
        assert(expectedNumberOfDaysDidChange: (),
               expectedHasModificationsToSave: false,
               expectedNumberOfDays: 3)
    }

    func testSave() throws {
        // arrange
        let expectedNumberOfDays: Int = 4
        
        // act
        sut.set(numberOfDays: expectedNumberOfDays)
        sut.save()
        
        // assert
        do {
            var expectedSetting: BaseResultModel.Setting = dummySetting
            expectedSetting.numberOfDays = expectedNumberOfDays
            assert(expectedNumberOfDaysDidChange: (),
                   expectedHasModificationsToSave: true,
                   expectedSetting: expectedSetting,
                   expectedNumberOfDays: expectedNumberOfDays)
        }
    }
    
    func testCancelWithoutModificationToSave() throws {
        // arrange is done in `setUp`
        
        // act
        sut.attemptToCancel()
        
        // assert
        assert(expectedHasModificationsToSave: false,
               expectedCancellationNeedsToBeConfirmed: false,
               expectedNumberOfDays: dummySetting.numberOfDays)
        
        // act
        removeAllReceivedValue()
        sut.cancel()
        
        // assert
        assert(expectedCancel: (),
               expectedNumberOfDays: dummySetting.numberOfDays)
    }
    
    func testCancelWithModificationToSave() throws {
        // arrange
        let expectedNumberOfDays: Int = 4
        
        // act
        sut.set(numberOfDays: expectedNumberOfDays)
        sut.attemptToCancel()
        
        // assert
        assert(expectedNumberOfDaysDidChange: (),
               expectedHasModificationsToSave: true,
               expectedCancellationNeedsToBeConfirmed: true,
               expectedNumberOfDays: expectedNumberOfDays)
    }
}

// MARK: - private method
private extension SettingModelTests {
    func removeAllReceivedValue() {
        receivedNumberOfDaysDidChange = nil
        receivedBaseCurrencyCodeDidChange = nil
        receivedCurrencyCodeOfInterestDidChange = nil
        receivedHasModificationsToSave = nil
        receivedCancellationNeedsToBeConfirmed = nil
        
        receivedSetting = nil
        receivedCancel = nil
    }
    
    func assert(expectedNumberOfDaysDidChange: Void? = nil,
                expectedBaseCurrencyCodeDidChange: Void? = nil,
                expectedCurrencyCodeOfInterestDidChange: Void? = nil,
                expectedHasModificationsToSave: Bool? = nil,
                expectedCancellationNeedsToBeConfirmed: Bool? = nil,
                expectedSetting: BaseResultModel.Setting? = nil,
                expectedCancel: Void? = nil,
                expectedNumberOfDays: Int) {
        if expectedNumberOfDaysDidChange == nil {
            XCTAssertNil(receivedNumberOfDaysDidChange)
        }
        else {
            XCTAssertNotNil(receivedNumberOfDaysDidChange)
        }
        
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
        XCTAssertEqual(expectedCancellationNeedsToBeConfirmed, receivedCancellationNeedsToBeConfirmed)
        
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
