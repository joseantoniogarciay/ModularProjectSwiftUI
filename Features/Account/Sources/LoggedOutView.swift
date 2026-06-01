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

    // Validation errors shown inline
    @State private var identifierError: String?
    @State private var passwordError: String?

    @Environment(\.bannerPresenter) private var bannerPresenter

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    SharedUIAsset.logo.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                        .padding(.bottom, 40)

                    // Header
                    VStack(spacing: 8) {
                        Text(CoreStrings.accountLoggedOutTitle)
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(CoreStrings.accountLoggedOutSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)

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
                    .padding(.bottom, 24)

                    // Actions
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
                        .buttonStyle(TextLinkButtonStyle())
                        .accessibilityAddTraits(.isLink)
                    }
                    .padding(.top, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Drag-to-dismiss the keyboard, matching the UIKit `keyboardDismissMode = .interactive`.
            .scrollDismissesKeyboard(.interactively)
        }
        .background(SharedUIAsset.background.swiftUIColor.ignoresSafeArea())
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
            bannerPresenter?.show(BannerPayload(message: message(for: error), style: .error))
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
