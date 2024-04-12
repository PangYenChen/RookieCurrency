import Foundation
import Combine

extension Publisher {
    func convertOutputToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map { output in Result<Output, Failure>.success(output) }
            .catch { failure in Just(Result<Output, Failure>.failure(failure)) }
            .eraseToAnyPublisher()
    }
    
    func resultFilterSuccess<Success, Failure>() -> AnyPublisher<Success, Never>
    where Self.Output == Result<Success, Failure>, Self.Failure == Never {
        compactMap { result in try? result.get() }
            .eraseToAnyPublisher()
    }
    
    func resultFilterFailure<Success, Failure>() -> AnyPublisher<Failure, Never>
    where Self.Output == Result<Success, Failure>,
          Self.Failure == Never {
        compactMap { result in
            guard case .failure(let failure) = result else { return nil }
            return failure
        }
        .eraseToAnyPublisher()
    }
    
    /// This operator is different form RxSwift, but designed to fit the usage for this project.
    /// In the use case of this project, `Failure` is always `Never`, and flow never completes.
    func withLatestFrom<Other: Publisher>(_ other: Other) -> AnyPublisher<(selfOutput: Output, otherOutput: Other.Output), Self.Failure>
    where Self.Failure == Other.Failure, Self.Failure == Never {
        drop(untilOutputFrom: other.first())
            .map { selfOutput in (selfOutput: selfOutput, token: UUID()) }
            .combineLatest(other) { tuple, otherOutput in (tuple: tuple, otherOutput: otherOutput) }
            .removeDuplicates(by: { lhs, rhs in lhs.tuple.token == rhs.tuple.token })
            .map { tuple, otherOutput in (selfOutput: tuple.selfOutput, otherOutput: otherOutput) }
            .eraseToAnyPublisher()
    }
}
