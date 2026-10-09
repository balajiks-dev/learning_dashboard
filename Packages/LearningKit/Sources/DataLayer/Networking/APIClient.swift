import Foundation

/// Builds requests, attaches the bearer token, maps status codes and decodes.
/// Knows nothing about which transport actually carries the bytes.
public final class APIClient: Sendable {
    private let baseURL: URL
    private let http: any HTTPClient
    private let sessionStorage: any SessionStorage

    public init(baseURL: URL, http: any HTTPClient, sessionStorage: any SessionStorage) {
        self.baseURL = baseURL
        self.http = http
        self.sessionStorage = sessionStorage
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await perform(endpoint)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw NetworkError.decoding
        }
    }

    func send(_ endpoint: Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(_ endpoint: Endpoint) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.requiresAuth, let token = sessionStorage.load()?.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await http.send(request)
        switch response.statusCode {
        case 200..<300: return data
        case 401: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        default: throw NetworkError.server(statusCode: response.statusCode)
        }
    }
}
