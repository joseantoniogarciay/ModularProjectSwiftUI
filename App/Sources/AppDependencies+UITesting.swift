#if DEBUG
import Account
import Cart
import Core
import Foundation
import Pokemon

// MARK: - UI test dependency graph

extension AppDependencies {
    /// Replaces every network-dependent repository with an in-memory stub so UI tests
    /// run without a live server and complete in milliseconds.
    /// Activated by passing `--uitesting` in `XCUIApplication.launchArguments`.
    static func uitesting() -> AppDependencies {
        let pokemonStore = PokemonStore(repository: UITestPokemonRepository())
        let accountStore = AccountStore(session: UITestAuthSession())
        let cartStore = CartStore(
            cartRepository: UITestCartRepository(),
            productsRepository: UITestProductsRepository(),
            onSimulateExpiration: {}
        )
        return AppDependencies(
            pokemonStore: pokemonStore,
            accountStore: accountStore,
            cartStore: cartStore
        )
    }

    /// Returns dependencies where `pokemonRepository` always fails with `.noConnection`.
    /// Activated by `--uitesting-list-error` in `XCUIApplication.launchArguments`.
    static func uitestingWithListError() -> AppDependencies {
        let pokemonStore = PokemonStore(repository: UITestErrorPokemonRepository())
        let accountStore = AccountStore(session: UITestAuthSession())
        let cartStore = CartStore(
            cartRepository: UITestCartRepository(),
            productsRepository: UITestProductsRepository(),
            onSimulateExpiration: {}
        )
        return AppDependencies(
            pokemonStore: pokemonStore,
            accountStore: accountStore,
            cartStore: cartStore
        )
    }
}

// MARK: - Stubs

/// In-memory Pokémon repository — returns 5 sample Pokémon instantly, no network.
private struct UITestPokemonRepository: PokemonRepository {
    private static let samples: [Pokemon] = [
        Pokemon(id: 1, name: "bulbasaur", imageURL: nil),
        Pokemon(id: 2, name: "ivysaur", imageURL: nil),
        Pokemon(id: 3, name: "venusaur", imageURL: nil),
        Pokemon(id: 4, name: "charmander", imageURL: nil),
        Pokemon(id: 5, name: "charmeleon", imageURL: nil),
    ]

    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        guard offset == 0 else { return [] }
        return Self.samples
    }

    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        let name = Self.samples.first { $0.id == id }?.name ?? "pokemon"
        return PokemonDetail(
            id: id,
            name: name,
            imageURL: nil,
            types: ["grass"],
            heightDecimetres: 7,
            weightHectograms: 69,
            stats: [
                PokemonStat(name: "hp", baseValue: 45),
                PokemonStat(name: "attack", baseValue: 49),
                PokemonStat(name: "defense", baseValue: 49),
            ]
        )
    }
}

/// Repository that always throws `.noConnection` — used by `--uitesting-list-error`
/// to exercise the full-screen error state in PokemonListView.
private struct UITestErrorPokemonRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        throw .noConnection
    }

    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw .noConnection
    }
}

@MainActor
private final class UITestAuthSession: AuthSession {
    var authState: AuthState = .anonymous(.initial)

    func authStates() -> AsyncStream<AuthState> {
        AsyncStream { continuation in
            continuation.yield(.anonymous(.initial))
            // Intentionally left open: AccountStore.start() suspends on `for await`
            // for the process lifetime. UI tests are short-lived; this is acceptable.
        }
    }

    func restore() async {}
    func login(identifier: String, password: String) async throws(LoginError) {}
    func register(username: String, email: String, password: String) async throws(SignUpError) {}
    func refreshCurrentUser() async throws(CurrentUserError) {}
    func logout() async {}
    func expireSession() async {}
}

private struct UITestCartRepository: CartRepository {
    func get() async throws(CartFetchError) -> Cart {
        Cart(items: [], total: 0)
    }
    func addItem(productId: String) async throws(CartAddItemError) -> Cart {
        Cart(items: [], total: 0)
    }
}

private struct UITestProductsRepository: ProductsRepository {
    func list() async throws(ProductsListError) -> [Product] { [] }
}
#endif
