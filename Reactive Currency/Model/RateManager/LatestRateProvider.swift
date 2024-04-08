import Foundation
import Combine

protocol LatestRateProviderProtocol {
    func latestRatePublisher() -> AnyPublisher<ResponseDataModel.LatestRate, Error>
}
