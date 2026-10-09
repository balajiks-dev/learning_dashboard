import Domain

public final class DefaultAuthRepository: AuthRepository {
    private let client: APIClient
    private let sessionStorage: any SessionStorage

    public init(client: APIClient, sessionStorage: any SessionStorage) {
        self.client = client
        self.sessionStorage = sessionStorage
    }

    public func login(email: String, password: String) async throws -> User {
        do {
            let response: LoginResponseDTO = try await client.request(.login(email: email, password: password))
            try sessionStorage.save(StoredSession(token: response.token, user: response.user))
            return response.user.domain
        } catch NetworkError.unauthorized {
            throw DomainError.invalidCredentials
        } catch {
            throw DomainError(mapping: error)
        }
    }

    public func currentUser() async -> User? {
        sessionStorage.load()?.user.domain
    }

    public func logout() async {
        // Production: also revoke the token server-side (best effort).
        sessionStorage.clear()
    }
}
