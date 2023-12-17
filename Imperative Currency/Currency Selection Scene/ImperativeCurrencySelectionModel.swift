import Foundation

protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var stateHandler: ((Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void)? { get set }
}
