import Core
import Pokemon
import SwiftUI

/// App root view — mirrors `AppRootCoordinator` / `UITabBarController` from the UIKit project.
///
/// Hosts one tab per feature. Navigation within each tab is owned by its flow view
/// (e.g. `PokemonFlowView`), which plays the role of the UIKit coordinator.
struct RootView: View {
    let pokemonStore: PokemonStore

    var body: some View {
        TabView {
            PokemonFlowView(store: pokemonStore)
                .tabItem {
                    Label(CoreStrings.pokemonTitle, systemImage: "list.bullet")
                }

            AccountPlaceholderView()
                .tabItem {
                    Label(CoreStrings.accountTitle, systemImage: "person.crop.circle")
                }
        }
        // Tab tint defaults to the system accent colour.
        // Add a SharedUIAsset.accent colour asset to SharedUI/Resources if a custom brand colour is needed.
    }
}

// MARK: - Account placeholder

/// Temporary placeholder until the Account feature is ported to SwiftUI.
private struct AccountPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                CoreStrings.accountTitle,
                systemImage: "person.crop.circle",
                description: Text("Coming soon")
            )
            .navigationTitle(CoreStrings.accountTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(pokemonStore: PokemonStore(repository: PreviewRepository()))
}

private struct PreviewRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        [
            Pokemon(id: 1, name: "bulbasaur", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png")),
        ]
    }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.unknown(URLError(.unknown))
    }
}
