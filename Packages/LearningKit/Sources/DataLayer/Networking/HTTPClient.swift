import Foundation

/// The single seam between the app and the transport. Production uses
/// `URLSessionHTTPClient`; the demo build and tests use `MockHTTPClient`.
public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            return (data, http)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
                 .internationalRoamingOff, .cannotFindHost, .cannotConnectToHost:
                throw NetworkError.offline
            case .timedOut:
                throw NetworkError.timeout
            case .cancelled:
                throw CancellationError()
            default:
                throw NetworkError.transport
            }
        }
    }
}
