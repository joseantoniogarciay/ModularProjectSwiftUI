import Account
import Cart
import Core
import Pokemon
import SwiftUI

/// App root view — mirrors `AppRootCoordinator` / `UITabBarController` from the UIKit project.
///
/// Hosts one tab per feature. Navigation within each tab is owned by its flow view
/// (e.g. `PokemonFlowView`, `AccountFlowView`), which plays the role of the UIKit coordinator.
struct RootView: View {
    let pokemonStore: PokemonStore
    let accountStore: AccountStore
    let cartStore: CartStore

    var body: some View {
        TabView {
            PokemonFlowView(store: pokemonStore)
                .tabItem {
                    Label(CoreStrings.pokemonTitle, systemImage: "list.bullet")
                }

            CartFlowView(store: cartStore)
                .tabItem {
                    Label(CoreStrings.cartTitle, systemImage: "cart")
                }

            AccountFlowView(store: accountStore)
                .tabItem {
                    Label(CoreStrings.accountTitle, systemImage: "person.crop.circle")
                }
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
        )
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
