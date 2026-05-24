import Core
import SwiftUI

/// SwiftUI equivalent of `PokemonCoordinator`.
///
/// Owns the `NavigationStack` and the `NavigationPath` for the Pokémon tab.
/// It is the single place that decides what to show for each navigation value —
/// `PokemonListView` emits `NavigationLink(value: pokemon.id)` without knowing
/// what comes next; this view declares the destination.
public struct PokemonFlowView: View {
    let store: PokemonStore
    @State private var path = NavigationPath()

    public init(store: PokemonStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $path) {
            PokemonListView(store: store)
                .navigationDestination(for: Pokemon.self) { pokemon in
                    PokemonDetailView(pokemon: pokemon, store: store)
                }
        }
    }
}

// MARK: - Previews

private struct PreviewRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        [
            Pokemon(id: 1, name: "bulbasaur", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png")),
            Pokemon(id: 4, name: "charmander", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png")),
            Pokemon(id: 7, name: "squirtle", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png")),
        ]
    }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.unknown(URLError(.unknown))
    }
}

#Preview("Flow – loaded") {
    PokemonFlowView(store: PokemonStore(repository: PreviewRepository()))
}
