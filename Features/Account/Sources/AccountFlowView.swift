import Core
import SharedUI
import SwiftUI

/// Root of the Account tab. Owns a NavigationStack and coordinates
/// between the logged-out flow and logged-in profile screen.
public struct AccountFlowView: View {
    let store: AccountStore

    @State private var path: [AccountRoute] = []

    @Environment(\.bannerPresenter) private var bannerPresenter

    enum AccountRoute: Hashable {
        case register
    }

    public init(store: AccountStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $path) {
            AccountView(store: store, onRegister: { path.append(.register) })
                .navigationTitle(CoreStrings.accountTitle)
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: AccountRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView(store: store, onSuccess: { path.removeLast() })
                    }
                }
        }
        .task { await store.start() }
        .onChange(of: store.sessionExpiredAlert) { _, expired in
            guard expired else { return }
            bannerPresenter?.show(BannerPayload(
                message: CoreStrings.accountSessionExpiredMessage,
                style: .warning,
                iconSystemName: "exclamationmark.triangle.fill"
            ))
            store.dismissSessionExpiredAlert()
        }
    }
}
