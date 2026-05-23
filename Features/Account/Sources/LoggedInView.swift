import Core
import SharedUI
import SwiftUI

/// Displays the authenticated user's profile and a logout button.
struct LoggedInView: View {
    let store: AccountStore
    let user: User

    @State private var showLogoutConfirm = false
    @State private var isLoggingOut = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(CoreStrings.accountGreetingFormat(user.username))
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                profileCard

                Spacer(minLength: 0)
            }
            .padding(24)
        }
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            user: User(id: "42", username: "sara", email: "sara@example.com", role: "admin", avatarURL: nil)
        )
        .navigationTitle(CoreStrings.accountTitle)
    }
}
#endif
