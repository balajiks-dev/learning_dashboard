import Testing
@testable import Domain

@Suite("Credentials validation")
struct CredentialsValidatorTests {
    @Test("Valid credentials pass (email is trimmed and case-insensitive)")
    func valid() {
        #expect(CredentialsValidator.validate(email: "  Learner@Example.com ", password: "password123").isValid)
    }

    @Test("Email issues", arguments: [
        ("", CredentialsValidator.EmailIssue.empty),
        ("   ", .empty),
        ("learner", .malformed),
        ("learner@", .malformed),
        ("learner@example", .malformed),
    ])
    func emailIssues(email: String, issue: CredentialsValidator.EmailIssue) {
        #expect(CredentialsValidator.validate(email: email, password: "password123").email == issue)
    }

    @Test("Password issues")
    func passwordIssues() {
        #expect(CredentialsValidator.validate(email: "a@b.co", password: "").password == .empty)
        #expect(CredentialsValidator.validate(email: "a@b.co", password: "12345").password == .tooShort(minimum: 6))
    }
}
