import XCTest
import Combine

@testable import ReactiveCurrency

final class SettingModelTests: XCTestCase {
    private var sut: SettingModel!
    
    private var dummySetting: BaseResultModel.Setting!
    private var saveSettingSubject: PassthroughSubject<BaseResultModel.Setting, Never>!
    private var cancelSubject: PassthroughSubject<Void, Never>!
    private var dummyCurrencyDescriber: CurrencyDescriberProtocol!
    
    private var anyCancellableSet: Set<AnyCancellable>!

    override func setUp() {
        dummySetting = (numberOfDays: 3,
                   baseCurrencyCode: "TWD",
                   currencyCodeOfInterest: ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"])
        saveSettingSubject = PassthroughSubject<BaseResultModel.Setting, Never>()
        cancelSubject = PassthroughSubject<Void, Never>()
        dummyCurrencyDescriber = TestDouble.CurrencyDescriber()
        
        sut = SettingModel(setting: dummySetting,
                           saveSettingSubscriber: AnySubscriber(saveSettingSubject),
                           cancelSubscriber: AnySubscriber(cancelSubject),
                           currencyDescriber: dummyCurrencyDescriber)
        
        anyCancellableSet = Set<AnyCancellable>()
    }

    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        dummyCurrencyDescriber = nil
        cancelSubject = nil
        saveSettingSubject = nil
        dummySetting = nil
    }

    func testNumberOfDaysChanges() throws {
        // arrange
        var receivedHasModificationsToSave: Bool?
        var receivedNumberOfDaysDidChange: Void?
        
        sut.numberOfDaysDidChange
            .sink { numberOfDaysDidChange in receivedNumberOfDaysDidChange = numberOfDaysDidChange }
            .store(in: &anyCancellableSet)
        
        sut.hasModificationsToSave
            .sink { modificationsToSave in receivedHasModificationsToSave = modificationsToSave }
            .store(in: &anyCancellableSet)
        
        // act
        sut.set(numberOfDays: 4)
        
        // assert
        do {
            let receivedHasModificationsToSave: Bool = try XCTUnwrap(receivedHasModificationsToSave)
            XCTAssert(receivedHasModificationsToSave)
        }
        XCTAssertEqual(sut.numberOfDays, 4)
        XCTAssertNotNil(receivedNumberOfDaysDidChange)
        
        // arrange
        receivedHasModificationsToSave = nil
        receivedNumberOfDaysDidChange = nil
        
        // act
        sut.set(numberOfDays: 3)
        
        // assert
        do {
            let receivedHasModificationsToSave: Bool = try XCTUnwrap(receivedHasModificationsToSave)
            XCTAssertFalse(receivedHasModificationsToSave)
        }
        XCTAssertEqual(sut.numberOfDays, 3)
        XCTAssertNotNil(receivedNumberOfDaysDidChange)
    }

    func testSave() {
        
    }
    
    func testCancel() {
        
    }

}
