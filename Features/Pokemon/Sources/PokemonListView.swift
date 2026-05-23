import Core
import SharedUI
import SwiftUI

public struct PokemonListView: View {
    var store: PokemonStore   // shared — @Observable tracks access automatically

    public init(store: PokemonStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pokémon")
                .refreshable { await store.loadFirstPage() }
        }
        // Attached to NavigationStack so the task survives content-type changes.
        .task { await store.loadFirstPage() }
    }

    @ViewBuilder
    private var content: some View {
        switch store.listState {
        case .idle, .loading where store.pokemons.isEmpty:
            LoadingView()
        case .error(let error) where store.pokemons.isEmpty:
            RetryView(message: listErrorMessage(error)) {
                Task { await store.loadFirstPage() }
            }
        default:
            pokemonList
        }
    }

    private var pokemonList: some View {
        List(store.pokemons, id: \.id) { pokemon in
            NavigationLink(value: pokemon.id) {
                PokemonRowView(pokemon: pokemon)
            }
            .task { await store.loadMoreIfNeeded(currentItem: pokemon) }
        }
        .navigationDestination(for: Int.self) { id in
            PokemonDetailView(pokemonID: id, store: store)
        }
    }

    private func listErrorMessage(_ error: PokemonListError) -> String {
        switch error {
        case .noConnection: return "No internet connection."
        case .unknown: return "Something went wrong."
        }
    }
}

// MARK: - Previews

private struct PreviewRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        [
            Pokemon(id: 1,  name: "bulbasaur",  imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png")),
            Pokemon(id: 4,  name: "charmander", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png")),
            Pokemon(id: 7,  name: "squirtle",   imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png")),
            Pokemon(id: 25, name: "pikachu",    imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")),
            Pokemon(id: 39, name: "jigglypuff", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/39.png")),
        ]
    }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.unknown(URLError(.unknown))
    }
}

private struct ErrorRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        throw PokemonListError.noConnection
    }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.noConnection
    }
}

#Preview("List – loaded") {
    PokemonListView(store: PokemonStore(repository: PreviewRepository()))
}

#Preview("List – error") {
    PokemonListView(store: PokemonStore(repository: ErrorRepository()))
}
