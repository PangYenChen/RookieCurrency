import Foundation
import Combine

protocol ReactiveCurrencySelectionModel: CurrencySelectionModelProtocol {
    var state: AnyPublisher<Result<[ResponseDataModel.CurrencyCode: String], Error>, Never> { get }
}
