import Foundation

protocol LatestRateProviderProtocol {
    func latestRate(latestRateResultHandler: @escaping LatestRateResultHandler)
}

extension LatestRateProviderProtocol {
    typealias LatestRateResultHandler = (_ latestRateResult: Result<ResponseDataModel.LatestRate, Error>) -> Void
}
