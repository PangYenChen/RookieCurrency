import Foundation

protocol LatestRateProviderProtocol {
    func latestRate(id: String, resultHandler: @escaping LatestRateResultHandler)
}

extension LatestRateProviderProtocol {
    typealias LatestRateResultHandler = (_ rateResult: Result<ResponseDataModel.LatestRate, Error>) -> Void
}
