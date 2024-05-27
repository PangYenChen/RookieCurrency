import Foundation
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class UserSettingManager: UserSettingManagerProtocol {
        var numberOfDays: Int = 3
        
        var baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        
        var resultOrder: BaseResultModel.Order = .decreasing
        
        var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "JPY"]
    }
}
