public protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> User
    /// The user of a previously persisted session, if any.
    func currentUser() async -> User?
    func logout() async
}
