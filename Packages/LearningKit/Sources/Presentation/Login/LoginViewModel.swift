import Domain
import Observation

@MainActor
@Observable
public final class LoginViewModel {
    public var email = "" {
        didSet { fieldsDidChange() }
    }
    public var password = "" {
        didSet { fieldsDidChange() }
    }

    public private(set) var emailError: String?
    public private(set) var passwordError: String?
    public private(set) var submitError: String?
    public private(set) var isSubmitting = false

    /// Errors appear only after the first submit attempt, then update live.
    private var hasAttemptedSubmit = false
    private let login: LoginUseCase
    private let onSuccess: @MainActor (User) -> Void

    public init(login: LoginUseCase, onSuccess: @escaping @MainActor (User) -> Void) {
        self.login = login
        self.onSuccess = onSuccess
    }

    public func submit() async {
        guard !isSubmitting else { return }
        hasAttemptedSubmit = true
        guard validate() else { return }

        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        do {
            let user = try await login(email: email, password: password)
            onSuccess(user)
        } catch {
            submitError = DomainError(error).userMessage
        }
    }

    private func fieldsDidChange() {
        submitError = nil
        if hasAttemptedSubmit { validate() }
    }

    @discardableResult
    private func validate() -> Bool {
        let report = CredentialsValidator.validate(email: email, password: password)
        emailError = switch report.email {
        case .empty: "Enter your email address."
        case .malformed: "Enter a valid email address."
        case nil: nil
        }
        passwordError = switch report.password {
        case .empty: "Enter your password."
        case .tooShort(let minimum): "Password must be at least \(minimum) characters."
        case nil: nil
        }
        return report.isValid
    }
}

extension DomainError {
    init(_ error: any Error) {
        self = (error as? DomainError) ?? .unexpected
    }
}
