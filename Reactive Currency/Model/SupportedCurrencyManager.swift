import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    private var wrappedSupportedSymbols: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
    
    func supportedCurrency() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        if let supportedCurrencyDescriptionDictionary {
            return Just(supportedCurrencyDescriptionDictionary)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            if let wrappedSupportedSymbols {
                return wrappedSupportedSymbols
            }
            else {
                let wrappedSupportedSymbols: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> = supportedCurrencyProvider.supportedCurrency()
                    .map { $0.symbols }
                    .handleEvents(
                        receiveOutput: { supportedCurrencyDescriptionDictionary in
                            self.supportedCurrencyDescriptionDictionary = supportedCurrencyDescriptionDictionary
                        },
                        receiveCompletion: { _ in self.wrappedSupportedSymbols = nil },
                        receiveCancel: { self.wrappedSupportedSymbols = nil }
                    )
                    .share()
                    .eraseToAnyPublisher()
                
                self.wrappedSupportedSymbols = wrappedSupportedSymbols
                
                return wrappedSupportedSymbols
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        supportedCurrency()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
