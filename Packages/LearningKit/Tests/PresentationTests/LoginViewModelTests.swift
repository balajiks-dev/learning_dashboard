import Domain
import Testing
@testable import Presentation

@MainActor
@Suite("Login screen")
struct LoginViewModelTests {
    @Test("Invalid input shows field errors and never hits the network")
    func invalidInput() async {
        let repository = FakeAuthRepository()
        let viewModel = LoginViewModel(login: LoginUseCase(repository: repository), onSuccess: { _ in })
        viewModel.email = "not-an-email"
        viewModel.password = "123"

        await viewModel.submit()

        #expect(viewModel.emailError == "Enter a valid email address.")
        #expect(viewModel.passwordError == "Password must be at least 6 characters.")
        #expect(await repository.loginCalls == 0)
    }

    @Test("Wrong credentials show an error message")
    func wrongCredentials() async {
        let repository = FakeAuthRepository(result: .failure(.invalidCredentials))
        let viewModel = LoginViewModel(login: LoginUseCase(repository: repository), onSuccess: { _ in })
        viewModel.email = "learner@example.com"
        viewModel.password = "wrong-password"

        await viewModel.submit()

        #expect(viewModel.submitError == "Incorrect email or password.")
        #expect(viewModel.isSubmitting == false)
    }

    @Test("Valid credentials sign the user in")
    func success() async {
        var signedIn: User?
        let viewModel = LoginViewModel(login: LoginUseCase(repository: FakeAuthRepository()), onSuccess: { signedIn = $0 })
        viewModel.email = "learner@example.com"
        viewModel.password = "password123"

        await viewModel.submit()

        #expect(signedIn == .sample)
        #expect(viewModel.submitError == nil)
    }
}
