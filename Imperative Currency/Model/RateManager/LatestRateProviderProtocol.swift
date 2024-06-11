import Foundation

protocol LatestRateProviderProtocol {
    func latestRate(traceIdentifier: String, resultHandler: @escaping LatestRateResultHandler)
}

extension LatestRateProviderProtocol {
    typealias LatestRateResultHandler = (_ rateResult: Result<ResponseDataModel.LatestRate, Error>) -> Void
}
