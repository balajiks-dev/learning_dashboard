import Domain

extension DomainError {
    /// Collapses every data-layer error into the vocabulary the rest of the app speaks.
    init(mapping error: any Error) {
        switch error {
        case let error as DomainError:
            self = error
        case let error as NetworkError:
            switch error {
            case .offline, .timeout: self = .offline
            case .unauthorized: self = .sessionExpired
            case .notFound: self = .notFound
            case .server(let statusCode): self = .server(statusCode: statusCode)
            case .invalidResponse, .decoding, .transport: self = .server(statusCode: nil)
            }
        case let error as PersistenceError:
            self = error == .courseNotCached || error == .lessonNotCached ? .notFound : .persistence
        case is KeychainSessionStorage.KeychainError:
            self = .persistence
        default:
            self = .unexpected
        }
    }
}
