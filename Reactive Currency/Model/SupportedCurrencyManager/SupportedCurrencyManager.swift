import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    override init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
                  locale: Locale = Locale.autoupdatingCurrent,
                  internalSerialDispatchQueue: DispatchQueue,
                  externalConcurrentDispatchQueue: DispatchQueue) {
        currentPublisher = nil
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale,
                   internalSerialDispatchQueue: internalSerialDispatchQueue,
                   externalConcurrentDispatchQueue: externalConcurrentDispatchQueue)
    }
    
    private var currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
    
    func supportedCurrency() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        Just(())
            .receive(on: internalSerialDispatchQueue)
            .flatMap { [unowned self] _ in
                if let cachedValue {
                    return Just(cachedValue)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                else {
                    if let currentPublisher {
                        return currentPublisher
                    }
                    else {
                        let currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> = supportedCurrencyProvider.supportedCurrencyPublisher()
                            .receive(on: internalSerialDispatchQueue)
                            .map { $0.symbols }
                            .handleEvents(
                                receiveOutput: { [unowned self] supportedCurrencyDescriptionDictionary in
                                    cachedValue = supportedCurrencyDescriptionDictionary
                                },
                                receiveCompletion: { [unowned self] _ in self.currentPublisher = nil },
                                receiveCancel: { [unowned self]  in self.currentPublisher = nil }
                            )
                            .share()
                            .eraseToAnyPublisher()
                        
                        self.currentPublisher = currentPublisher
                        
                        return currentPublisher
                    }
                }
            }
            .receive(on: externalConcurrentDispatchQueue)
            .eraseToAnyPublisher()
    }
    
    func prefetchSupportedCurrency() {
        supportedCurrency()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
