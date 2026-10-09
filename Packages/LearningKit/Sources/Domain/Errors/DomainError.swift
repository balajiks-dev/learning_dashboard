/// Every failure the app can surface, independent of HTTP, SwiftData or
/// Keychain details. The data layer maps its own errors into these cases.
public enum DomainError: Error, Equatable, Hashable, Sendable {
    case offline
    case invalidInput
    case invalidCredentials
    case sessionExpired
    case server(statusCode: Int?)
    case notFound
    case persistence
    case unexpected
}
