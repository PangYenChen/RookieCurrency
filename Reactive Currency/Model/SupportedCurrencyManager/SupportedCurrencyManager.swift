import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    override init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol = Fetcher.shared,
                  locale: Locale = Locale.autoupdatingCurrent) {
        wrappedCurrentPublisher = ThreadSafeWrapper<AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?>(wrappedValue: nil)
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale)
    }
    
    private var wrappedCurrentPublisher: ThreadSafeWrapper<AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?>
    
    func supportedCurrency() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        let cachedValue: [ResponseDataModel.CurrencyCode: String]? = cache.readSynchronously { cachedDictionary in cachedDictionary }
        
        if let cachedValue {
            return Just(cachedValue)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            let currentPublisher = wrappedCurrentPublisher.readSynchronously { currentPublisher in currentPublisher }
            
            if let currentPublisher {
                return currentPublisher
            }
            else {
                let currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> = supportedCurrencyProvider.supportedCurrencyPublisher()
                    .map { $0.symbols }
                    .handleEvents(
                        receiveOutput: { [unowned self] supportedCurrencyDescriptionDictionary in
                            cache.writeAsynchronously { _ in supportedCurrencyDescriptionDictionary }
                        },
                        receiveCompletion: { [unowned self] _ in
                            wrappedCurrentPublisher.writeAsynchronously { _ in nil }
                        },
                        receiveCancel: { [unowned self] in
                            wrappedCurrentPublisher.writeAsynchronously { _ in nil }
                        }
                    )
                    .share()
                    .eraseToAnyPublisher()
                
                wrappedCurrentPublisher.writeAsynchronously { _ in currentPublisher }
                
                return currentPublisher
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        supportedCurrency()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
