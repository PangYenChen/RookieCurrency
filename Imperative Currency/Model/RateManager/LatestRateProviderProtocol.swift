import Foundation

protocol LatestRateProviderProtocol {
    func rate(resultHandler: @escaping LatestRateResultHandler)
}

extension LatestRateProviderProtocol {
    typealias LatestRateResultHandler = (_ latestRateResult: Result<ResponseDataModel.LatestRate, Error>) -> Void
}
