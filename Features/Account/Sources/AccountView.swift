import Core
import SharedUI
import SwiftUI

/// Switches between the loading spinner, logged-out form, and
/// logged-in profile based on the current AuthState.
struct AccountView: View {
    let store: AccountStore
    let onRegister: () -> Void
    let onShowCart: () -> Void

    var body: some View {
        switch store.authState {
        case .unknown:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SharedUIAsset.background.swiftUIColor.ignoresSafeArea())

        case .anonymous:
            LoggedOutView(store: store, onRegister: onRegister)

        case .authenticated(let user):
            LoggedInView(store: store, user: user, onShowCart: onShowCart)
        }
    }
}
