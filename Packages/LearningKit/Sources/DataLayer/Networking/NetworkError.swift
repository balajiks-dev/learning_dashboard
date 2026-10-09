/// Transport-level failures. Never leaves the data layer: repositories map
/// these to `DomainError` via `DomainError.init(mapping:)`.
public enum NetworkError: Error, Equatable, Sendable {
    case offline
    case timeout
    case unauthorized
    case notFound
    case server(statusCode: Int)
    case invalidResponse
    case decoding
    case transport
}
