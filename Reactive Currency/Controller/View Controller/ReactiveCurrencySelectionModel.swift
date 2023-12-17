import Foundation
import Combine

protocol ReactiveCurrencySelectionModel: CurrencySelectionModelProtocol {
    var state: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never> { get }
}
