import Domain

public extension DomainError {
    var title: String {
        switch self {
        case .offline: "You're offline"
        case .invalidCredentials, .invalidInput: "Couldn't sign in"
        case .sessionExpired: "Session expired"
        case .notFound: "Not available"
        case .server, .persistence, .unexpected: "Something went wrong"
        }
    }

    var userMessage: String {
        switch self {
        case .offline: "Connect to the internet and try again."
        case .invalidInput: "Please fix the highlighted fields."
        case .invalidCredentials: "Incorrect email or password."
        case .sessionExpired: "Please sign in again."
        case .server: "Our servers are having trouble. Please try again in a moment."
        case .notFound: "This content is no longer available."
        case .persistence: "We couldn't save your progress on this device."
        case .unexpected: "Please try again."
        }
    }
}
