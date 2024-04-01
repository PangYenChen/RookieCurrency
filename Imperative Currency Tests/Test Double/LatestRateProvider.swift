import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class LatestRateProvider: LatestRateProviderProtocol {
        // MARK: - initializer
        init() {
            latestRateResultHandler = nil
        }
        
        // MARK: - private property
        private var latestRateResultHandler: LatestRateResultHandler?
        
        func rate(resultHandler: @escaping LatestRateResultHandler) {
            self.latestRateResultHandler = resultHandler
        }
        
        func executeLatestRateResultHandler(with result: Result<ResponseDataModel.LatestRate, Error>) {
            latestRateResultHandler?(result)
            latestRateResultHandler = nil
        }
    }
}
