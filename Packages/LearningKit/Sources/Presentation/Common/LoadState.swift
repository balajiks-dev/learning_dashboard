import Domain

/// The full set of states a screen can be in. Using one enum (instead of
/// `isLoading` + `error` + `items` flags) makes impossible combinations unrepresentable.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(DomainError)

    public var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }
}

extension LoadState: Equatable where Value: Equatable {}
