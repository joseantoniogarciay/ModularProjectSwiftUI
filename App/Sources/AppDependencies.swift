import Account
import Cart
import Core
import Data
import Foundation
import Networking
import Pokemon

@MainActor
final class AppDependencies {
    static let shared: AppDependencies = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitesting-list-error") { return AppDependencies.uitestingWithListError() }
        if args.contains("--uitesting") { return AppDependencies.uitesting() }
        #endif
        return AppDependencies()
    }()

    let pokemonStore: PokemonStore
    let accountStore: AccountStore
    let cartStore: CartStore

    private init() {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let userAgent = "iOS/\(os.majorVersion).\(os.minorVersion) ModularSwiftUI/1.0"

        // — Pokémon (unauthenticated)
        let pokemonClient = AlamofireNetClient(userAgent: userAgent)
        let pokeBaseURL = URL(string: "https://pokeapi.co/api/v2")!
        pokemonStore = PokemonStore(
            repository: PokemonRepositoryImpl(client: pokemonClient, baseURL: pokeBaseURL)
        )

        // — Auth stack (FreeAPI)
        let freeBaseURL = URL(string: "https://api.freeapi.app/api/v1")!
        let unauthClient = AlamofireNetClient(userAgent: userAgent)
        let tokenStore = KeychainTokenStore()
        let accessRepository = AccessRepositoryImpl(client: unauthClient, baseURL: freeBaseURL)
        let tokenRefreshing = AccessTokenRefreshingImpl(client: unauthClient, baseURL: freeBaseURL)
        let refresher = TokenRefresher(tokenStore: tokenStore, tokenRefreshing: tokenRefreshing)
        let authClient = AuthenticatedNetClient(base: unauthClient, refresher: refresher)
        let userRepository = UserRepositoryImpl(client: authClient, baseURL: freeBaseURL)
        let session = AuthSessionImpl(
            tokenStore: tokenStore,
            accessRepository: accessRepository,
            userRepository: userRepository
        )
        Task { [refresher, session] in
            await refresher.setOnTokensInvalidated { [weak session] in
                await session?.expireSession()
            }
        }
        accountStore = AccountStore(session: session)

        // — Cart (authenticated)
        let cartRepository = CartRepositoryImpl(client: authClient, baseURL: freeBaseURL)
        let productsRepository = ProductsRepositoryImpl(client: authClient, baseURL: freeBaseURL)
        cartStore = CartStore(
            cartRepository: cartRepository,
            productsRepository: productsRepository,
            onSimulateExpiration: { [weak session] in
                await session?.expireSession()
            }
        )
    }

    #if DEBUG
    /// Designated initializer used by UITesting factory methods only.
    /// Not available in release builds.
    internal init(pokemonStore: PokemonStore, accountStore: AccountStore, cartStore: CartStore) {
        self.pokemonStore = pokemonStore
        self.accountStore = accountStore
        self.cartStore = cartStore
    }
    #endif
}
