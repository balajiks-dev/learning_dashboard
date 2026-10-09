import Foundation

public enum CredentialsValidator {
    public static let minimumPasswordLength = 6

    public enum EmailIssue: Equatable, Sendable {
        case empty
        case malformed
    }

    public enum PasswordIssue: Equatable, Sendable {
        case empty
        case tooShort(minimum: Int)
    }

    public struct Report: Equatable, Sendable {
        public let email: EmailIssue?
        public let password: PasswordIssue?
        public var isValid: Bool { email == nil && password == nil }
    }

    public static func validate(email: String, password: String) -> Report {
        Report(email: emailIssue(email), password: passwordIssue(password))
    }

    public static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func emailIssue(_ raw: String) -> EmailIssue? {
        let email = normalizedEmail(raw)
        if email.isEmpty { return .empty }
        let pattern = #"^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) == nil ? .malformed : nil
    }

    private static func passwordIssue(_ password: String) -> PasswordIssue? {
        if password.isEmpty { return .empty }
        if password.count < minimumPasswordLength { return .tooShort(minimum: minimumPasswordLength) }
        return nil
    }
}
