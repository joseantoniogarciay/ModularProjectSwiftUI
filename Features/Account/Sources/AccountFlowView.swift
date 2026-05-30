import Core
import SharedUI
import SwiftUI

/// Root of the Account tab. Owns a NavigationStack and coordinates
/// between the logged-out flow, the logged-in profile screen, and the
/// cart (pushed from the profile, mirroring the UIKit coordinator delegate).
///
/// The cart screen is injected by the App layer so this module stays
/// decoupled from the Cart feature, matching `AppRootCoordinator`'s
/// `didRequestCartIn` delegate hand-off in the UIKit project.
public struct AccountFlowView<CartContent: View>: View {
    let store: AccountStore
    let cartContent: () -> CartContent

    @State private var path: [AccountRoute] = []

    @Environment(\.bannerPresenter) private var bannerPresenter

    enum AccountRoute: Hashable {
        case register
        case cart
    }

    public init(store: AccountStore, @ViewBuilder cartContent: @escaping () -> CartContent) {
        self.store = store
        self.cartContent = cartContent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            AccountView(
                store: store,
                onRegister: { path.append(.register) },
                onShowCart: { path.append(.cart) }
            )
            .navigationDestination(for: AccountRoute.self) { route in
                switch route {
                case .register:
                    RegisterView(store: store, onSuccess: { path.removeLast() })
                case .cart:
                    cartContent()
                }
            }
        }
        .task { await store.start() }
        .onChange(of: store.sessionExpiredAlert) { _, expired in
            guard expired else { return }
            path.removeAll()
            bannerPresenter?.show(BannerPayload(
                message: CoreStrings.accountSessionExpiredMessage,
                style: .warning,
                iconSystemName: "exclamationmark.triangle.fill"
            ))
            store.dismissSessionExpiredAlert()
        }
    }
}
