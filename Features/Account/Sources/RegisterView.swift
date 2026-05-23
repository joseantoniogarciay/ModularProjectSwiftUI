import Core
import SharedUI
import SwiftUI

/// Registration form — pushed from LoggedOutView.
struct RegisterView: View {
    let store: AccountStore
    let onSuccess: () -> Void

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var alertMessage: String?

    @State private var usernameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text(CoreStrings.accountRegisterScreenTitle)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(CoreStrings.accountRegisterSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Fields
                VStack(spacing: 8) {
                    ValidatedTextField(
                        placeholder: CoreStrings.accountUsernamePlaceholder,
                        text: $username,
                        error: usernameError,
                        contentType: .username
                    )
                    ValidatedTextField(
                        placeholder: CoreStrings.accountEmailPlaceholder,
                        text: $email,
                        error: emailError,
                        contentType: .emailAddress,
                        keyboardType: .emailAddress
                    )
                    ValidatedTextField(
                        placeholder: CoreStrings.accountPasswordPlaceholder,
                        text: $password,
                        isSecure: true,
                        error: passwordError,
                        contentType: .newPassword
                    )
                }

                Button(CoreStrings.accountRegisterButton) {
                    Task { await registerTapped() }
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                .disabled(isLoading)
            }
            .padding(24)
        }
        .navigationTitle(CoreStrings.accountRegisterScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize)
        .interactiveDismissDisabled(isLoading)
        .alert(alertMessage ?? "", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {}
    }

    private func registerTapped() async {
        usernameError = username.trimmingCharacters(in: .whitespaces).isEmpty
            ? CoreStrings.accountErrorFieldRequired : nil
        let emailTrimmed = email.trimmingCharacters(in: .whitespaces)
        emailError = emailTrimmed.isEmpty
            ? CoreStrings.accountErrorFieldRequired
            : (!emailTrimmed.contains("@") ? CoreStrings.accountErrorInvalidEmail : nil)
        passwordError = password.isEmpty
            ? CoreStrings.accountErrorFieldRequired : nil
        guard usernameError == nil, emailError == nil, passwordError == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await store.register(
                username: username.trimmingCharacters(in: .whitespaces),
                email: emailTrimmed,
                password: password
            )
            onSuccess()
        } catch {
            alertMessage = message(for: error)
        }
    }

    private func message(for error: SignUpError) -> String {
        switch error {
        case .noConnection:         return CoreStrings.errorNoConnection
        case .usernameOrEmailTaken: return CoreStrings.accountErrorTaken
        case .autoLoginFailed:      return CoreStrings.accountErrorGeneric
        case .unknown:              return CoreStrings.accountErrorGeneric
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Register") {
    NavigationStack {
        RegisterView(
            store: AccountStore(session: PreviewAuthSession()),
            onSuccess: {}
        )
    }
}
#endif
