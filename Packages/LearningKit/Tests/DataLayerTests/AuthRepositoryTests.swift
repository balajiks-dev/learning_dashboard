import Domain
import Foundation
import Testing
@testable import DataLayer

/// Runs the full networking stack (APIClient → MockHTTPClient → MockBackend)
/// so request building, status mapping and decoding are all covered.
@Suite("Auth repository")
struct AuthRepositoryTests {
    private let storage = InMemorySessionStorage()
    private let repository: DefaultAuthRepository

    init() throws {
        let http = MockHTTPClient(backend: try MockBackend(), connectivity: AlwaysOnline(), latency: .zero)
        let client = APIClient(baseURL: URL(string: "https://api.example.com/v1")!, http: http, sessionStorage: storage)
        repository = DefaultAuthRepository(client: client, sessionStorage: storage)
    }

    @Test("Successful login stores the session and restores the user")
    func loginSuccess() async throws {
        let user = try await repository.login(email: "learner@example.com", password: MockBackend.demoPassword)

        #expect(user.email == "learner@example.com")
        #expect(storage.load()?.token.isEmpty == false)
        #expect(await repository.currentUser() == user)
    }

    @Test("Wrong password maps HTTP 401 to .invalidCredentials and stores nothing")
    func loginFailure() async {
        await #expect(throws: DomainError.invalidCredentials) {
            try await repository.login(email: "learner@example.com", password: "wrong-password")
        }
        #expect(storage.load() == nil)
    }

    @Test("Logout clears the stored session")
    func logout() async throws {
        _ = try await repository.login(email: "learner@example.com", password: MockBackend.demoPassword)
        await repository.logout()
        #expect(await repository.currentUser() == nil)
    }
}
