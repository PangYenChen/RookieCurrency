import Foundation

extension AppUtility {
    
    private static var isFetching: Bool = false
    // TODO: 這裡應該會有同時性問題，等我讀完 concurrency 之後再處理
    private static var completionHandlers: [(Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void] = []
    
    static func fetchSupportedSymbols(completionHandler: @escaping (Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void) {
        
        if let supportedSymbols {
            completionHandler(.success(supportedSymbols))
        }
        else {
            completionHandlers.append(completionHandler)
            
            guard !isFetching else { return }
            
            Fetcher.shared.fetch(Endpoints.SupportedSymbols()) { result in
                if case .success(let supportedSymbols) = result {
                    Self.supportedSymbols = supportedSymbols.symbols
                }
                while let completionHandler = completionHandlers.popLast() {
                    completionHandler(result.map { $0.symbols })
                }
                isFetching = false
            }
        }
    }
    
    static func start() {
        fetchSupportedSymbols { _ in }
    }
}
