import Foundation

protocol LatestRateProviderProtocol {
    func latestRate(latestRateHandler: @escaping LatestRateHandler)
}

extension LatestRateProviderProtocol {
    typealias LatestRateHandler = (Result<ResponseDataModel.LatestRate, Error>) -> Void
}
