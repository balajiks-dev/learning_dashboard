import Domain
import Foundation

/// Transport that routes requests to the in-process `MockBackend` instead of
/// the internet. It still honours real connectivity, so switching the device
/// offline makes "API" calls fail exactly like `URLSession` would.
public struct MockHTTPClient: HTTPClient {
    private let backend: MockBackend
    private let connectivity: any ConnectivityMonitoring
    private let latency: Duration

    public init(backend: MockBackend, connectivity: any ConnectivityMonitoring, latency: Duration = .milliseconds(700)) {
        self.backend = backend
        self.connectivity = connectivity
        self.latency = latency
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard connectivity.isConnected else { throw NetworkError.offline }
        try await Task.sleep(for: latency)
        guard connectivity.isConnected else { throw NetworkError.offline }

        let (status, body) = await backend.handle(request)
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": "application/json"])
        else { throw NetworkError.invalidResponse }
        return (body, response)
    }
}
