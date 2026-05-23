import Core
import SharedUI
import SwiftUI

/// Login form — shown when the session is anonymous.
struct LoggedOutView: View {
    let store: AccountStore
    let onRegister: () -> Void

    @State private var identifier = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var alertMessage: String?

    // Validation errors shown inline
    @State private var identifierError: String?
    @State private var passwordError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text(CoreStrings.accountLoggedOutTitle)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(CoreStrings.accountLoggedOutSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Fields
                VStack(spacing: 8) {
                    ValidatedTextField(
                        placeholder: CoreStrings.accountUsernameOrEmailPlaceholder,
                        text: $identifier,
                        error: identifierError,
                        contentType: .username
                    )
                    ValidatedTextField(
                        placeholder: CoreStrings.accountPasswordPlaceholder,
                        text: $password,
                        isSecure: true,
                        error: passwordError,
                        contentType: .password
                    )
                }

                // Actions
                VStack(spacing: 16) {
                    Button(CoreStrings.accountLoginButton) {
                        Task { await loginTapped() }
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                    .disabled(isLoading)

                    HStack {
                        Spacer()
                        Button(CoreStrings.accountRegisterButton) {
                            onRegister()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .alert(alertMessage ?? "", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {}
    }

    private func loginTapped() async {
        identifierError = identifier.trimmingCharacters(in: .whitespaces).isEmpty
            ? CoreStrings.accountErrorFieldRequired : nil
        passwordError = password.isEmpty
            ? CoreStrings.accountErrorFieldRequired : nil
        guard identifierError == nil, passwordError == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await store.login(
                identifier: identifier.trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            alertMessage = message(for: error)
        }
    }

    private func message(for error: LoginError) -> String {
        switch error {
        case .noConnection:        return CoreStrings.errorNoConnection
        case .invalidCredentials:  return CoreStrings.accountErrorInvalidCredentials
        case .unknown:             return CoreStrings.accountErrorGeneric
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Logged Out") {
    NavigationStack {
        LoggedOutView(
            store: AccountStore(session: PreviewAuthSession()),
            onRegister: {}
        )
        .navigationTitle(CoreStrings.accountTitle)
    }
}
#endif
