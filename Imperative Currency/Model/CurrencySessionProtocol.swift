import Foundation

protocol CurrencySessionProtocol {
    func currencyDataTask(with request: URLRequest,
                          completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: CurrencySessionProtocol {
    func currencyDataTask(with request: URLRequest,
                          completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
