import Foundation
import Combine

protocol LatestRateProviderProtocol {
    func publisher() -> AnyPublisher<ResponseDataModel.LatestRate, Error>
}
