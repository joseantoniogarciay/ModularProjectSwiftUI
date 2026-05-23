import Pokemon
import SwiftUI

@main
struct ModularApp: App {
    var body: some Scene {
        WindowGroup {
            PokemonListView(store: AppDependencies.shared.pokemonStore)
        }
    }
}
