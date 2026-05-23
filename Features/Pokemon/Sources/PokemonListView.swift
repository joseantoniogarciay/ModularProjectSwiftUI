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
                .task { await store.loadFirstPage() }
                .refreshable { await store.loadFirstPage() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.listState {
        case .idle:
            EmptyView()
        case .loading where store.pokemons.isEmpty:
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
