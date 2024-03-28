import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class LatestRateProvider: LatestRateProviderProtocol {
        func latestRate(latestRateHandler: @escaping LatestRateHandler) {
        }
    }
}
