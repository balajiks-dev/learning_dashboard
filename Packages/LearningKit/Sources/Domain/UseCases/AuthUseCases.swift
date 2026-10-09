public struct LoginUseCase: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    /// Validates before touching the network, so bad input never costs a request.
    public func callAsFunction(email: String, password: String) async throws -> User {
        guard CredentialsValidator.validate(email: email, password: password).isValid else {
            throw DomainError.invalidInput
        }
        return try await repository.login(
            email: CredentialsValidator.normalizedEmail(email),
            password: password
        )
    }
}

public struct RestoreSessionUseCase: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction() async -> User? {
        await repository.currentUser()
    }
}

/// Signing out also wipes cached course data, so the next user of the device
/// never sees the previous user's progress.
public struct LogoutUseCase: Sendable {
    private let authRepository: any AuthRepository
    private let courseRepository: any CourseRepository

    public init(authRepository: any AuthRepository, courseRepository: any CourseRepository) {
        self.authRepository = authRepository
        self.courseRepository = courseRepository
    }

    public func callAsFunction() async {
        await authRepository.logout()
        await courseRepository.clearCache()
    }
}
