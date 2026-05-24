import Account
import Cart
import Core
import Pokemon
import SharedUI
import SwiftUI

/// App root view — mirrors `AppRootCoordinator` / `UITabBarController` from the UIKit project.
///
/// Hosts two tabs (Pokémon and Account), matching the UIKit tab bar. The cart is not a
/// tab: it's pushed from inside the Account profile, so the App layer injects `CartView`
/// into `AccountFlowView` — mirroring `AppRootCoordinator`'s `didRequestCartIn` hand-off.
struct RootView: View {
    let pokemonStore: PokemonStore
    let accountStore: AccountStore
    let cartStore: CartStore
    @Bindable var notificationRouter: NotificationRouter

    var body: some View {
        TabView {
            PokemonFlowView(store: pokemonStore)
                .environment(\.localNotificationScheduler, SystemLocalNotificationScheduler())
                .tabItem {
                    Label(CoreStrings.pokemonTitle, systemImage: "list.bullet")
                }

            AccountFlowView(store: accountStore) {
                CartView(store: cartStore)
            }
            .tabItem {
                Label(CoreStrings.accountTitle, systemImage: "person.crop.circle")
            }
        }
        .tint(SharedUIAsset.accent.swiftUIColor)
        .bannerOverlay()
        // Notification deep-link: present the Pokémon detail modally on top of any tab,
        // matching UIKit's PushNotificationRouter modal present.
        .sheet(item: $notificationRouter.deepLink) { link in
            NavigationStack {
                PokemonDetailView(pokemon: link.pokemon, store: pokemonStore)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(CoreStrings.commonClose) {
                                notificationRouter.deepLink = nil
                            }
                        }
                    }
            }
            // A sheet is its own presentation context: the root overlay renders behind it,
            // so host the overlay here too. Both share the same presenter, so the occluded
            // root copy is never visible — no duplication.
            .bannerOverlay()
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(
        pokemonStore: PokemonStore(repository: PreviewPokemonRepository()),
        accountStore: AccountStore(session: PreviewAccountSession()),
        cartStore: CartStore(
            cartRepository: PreviewCartRepository(),
            productsRepository: PreviewProductsRepository(),
            onSimulateExpiration: {}
        ),
        notificationRouter: NotificationRouter()
    )
}

private struct PreviewPokemonRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] { [] }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.unknown(URLError(.unknown))
    }
}

@MainActor
private final class PreviewAccountSession: AuthSession {
    var authState: AuthState = .anonymous(.initial)
    func authStates() -> AsyncStream<AuthState> { AsyncStream { $0.yield(.anonymous(.initial)) } }
    func restore() async {}
    func login(identifier: String, password: String) async throws(LoginError) {}
    func register(username: String, email: String, password: String) async throws(SignUpError) {}
    func refreshCurrentUser() async throws(CurrentUserError) {}
    func logout() async {}
    func expireSession() async {}
}

private struct PreviewCartRepository: CartRepository {
    func get() async throws(CartFetchError) -> Cart {
        Cart(items: [], total: 0)
    }
    func addItem(productId: String) async throws(CartAddItemError) -> Cart {
        Cart(items: [], total: 0)
    }
}

private struct PreviewProductsRepository: ProductsRepository {
    func list() async throws(ProductsListError) -> [Product] { [] }
}
