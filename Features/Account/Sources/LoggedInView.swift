import Core
import SharedUI
import SwiftUI

/// Displays the authenticated user's profile, a cart link, and a logout button.
struct LoggedInView: View {
    let store: AccountStore
    let user: User
    let onShowCart: () -> Void

    @State private var showLogoutConfirm = false
    @State private var isLoggingOut = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(CoreStrings.accountGreetingFormat(user.username))
                    .font(.largeTitle)
                    .accessibilityAddTraits(.isHeader)

                profileCard
                    .padding(.top, 24)

                Button(CoreStrings.accountCartButton) {
                    onShowCart()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        .background(SharedUIAsset.background.swiftUIColor.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLogoutConfirm = true
                } label: {
                    if isLoggingOut {
                        ProgressView()
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
                .accessibilityLabel(CoreStrings.accountLogoutButton)
                .disabled(isLoggingOut)
            }
        }
        .confirmationDialog(
            CoreStrings.accountLogoutConfirmTitle,
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button(CoreStrings.accountLogoutConfirmButton, role: .destructive) {
                Task {
                    isLoggingOut = true
                    await store.logout()
                    isLoggingOut = false
                }
            }
            Button(CoreStrings.accountCancelButton, role: .cancel) {}
        } message: {
            Text(CoreStrings.accountLogoutConfirmMessage)
        }
        .task { await store.refreshCurrentUser() }
    }

    private var profileCard: some View {
        VStack(spacing: 12) {
            infoRow(label: CoreStrings.accountProfileEmailLabel, value: user.email)
            Divider()
            infoRow(label: CoreStrings.accountProfileRoleLabel, value: user.role ?? "-")
            Divider()
            infoRow(label: CoreStrings.accountProfileIdLabel, value: user.id)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SharedUIAsset.cardBackground.swiftUIColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                .opacity(colorScheme == .dark ? 1 : 0)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.09), radius: 10, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Logged In") {
    NavigationStack {
        LoggedInView(
            store: AccountStore(session: PreviewAuthSession()),
            user: User(id: "42", username: "sara", email: "sara@example.com", role: "admin", avatarURL: nil),
            onShowCart: {}
        )
    }
}
#endif
