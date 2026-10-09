import DataLayer
import Presentation
import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                form
                #if DEBUG
                demoAccountHint
                #endif
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(Color.accentColor.gradient, in: .rect(cornerRadius: 24))
                .shadow(color: .accentColor.opacity(0.35), radius: 16, y: 8)
                .accessibilityHidden(true)
            Text("Learning Dashboard")
                .font(.largeTitle.bold())
            Text("Sign in to continue learning")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 48)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .fieldStyle(hasError: viewModel.emailError != nil)
                FieldError(message: viewModel.emailError)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: $viewModel.password)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                        }
                    }
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit(submit)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                }
                .fieldStyle(hasError: viewModel.passwordError != nil)
                FieldError(message: viewModel.passwordError)
            }

            if let submitError = viewModel.submitError {
                Label(submitError, systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.red.opacity(0.1), in: .rect(cornerRadius: 12))
                    .transition(.opacity)
            }

            Button(action: submit) {
                ZStack {
                    Text("Sign In").opacity(viewModel.isSubmitting ? 0 : 1)
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .disabled(viewModel.isSubmitting)
            .padding(.top, 8)
        }
        .animation(.default, value: viewModel.submitError)
        .animation(.default, value: viewModel.emailError)
        .animation(.default, value: viewModel.passwordError)
    }

    #if DEBUG
    private var demoAccountHint: some View {
        Button {
            viewModel.email = MockBackend.demoEmail
            viewModel.password = MockBackend.demoPassword
        } label: {
            Label("Use demo account · \(MockBackend.demoEmail) / \(MockBackend.demoPassword)", systemImage: "person.badge.key")
                .font(.footnote)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
    #endif

    private func submit() {
        focusedField = nil
        Task { await viewModel.submit() }
    }
}

private struct FieldError: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.leading, 4)
                .transition(.opacity)
        }
    }
}

private extension View {
    func fieldStyle(hasError: Bool) -> some View {
        padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(hasError ? Color.red : Color(.separator).opacity(0.5), lineWidth: hasError ? 1.5 : 0.5)
            }
    }
}
