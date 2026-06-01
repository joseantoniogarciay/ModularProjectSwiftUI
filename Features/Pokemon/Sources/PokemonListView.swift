import Core
import SharedUI
import SwiftUI

public struct PokemonListView: View {
    let store: PokemonStore

    /// Navigation is delegated to the owning flow so the `List` rows can stay plain
    /// `Button`s — a value-based `NavigationLink` would make `List` draw its own
    /// disclosure chevron on top of the card's chevron.
    private let onSelect: (Pokemon) -> Void

    /// Injected by the App layer; defaults to a no-op in previews. Keeps `UserNotifications` out
    /// of this view — scheduling goes through the `Core` contract.
    @Environment(\.localNotificationScheduler) private var notificationScheduler

    /// Shared AppStorage key keeps theme in sync with ModularApp.
    @AppStorage(ThemePreference.appStorageKey) private var themeRaw: String = ThemePreference.system.rawValue

    private var themePreference: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    public init(store: PokemonStore, onSelect: @escaping (Pokemon) -> Void = { _ in }) {
        self.store = store
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        Group { content }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ToolbarItemGroup treats both buttons as a single unit so they appear
                // in the same animation frame when returning from the detail.
                // Bell first → leftmost; theme second → rightmost. Matches UIKit's
                // rightBarButtonItems = [themeButton, notificationButton] where index 0 is trailing-most.
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await scheduleMewtwoNotification() }
                    } label: {
                        Image(systemName: "bell.badge")
                    }
                    .accessibilityLabel(CoreStrings.accessibilityNotifyMe)
                    // Override the TabView accent tint so the bar button renders in the
                    // label color (black in light, white in dark) like the UIKit nav bar.
                    .tint(.primary)

                    Button {
                        themeRaw = themePreference.next.rawValue
                    } label: {
                        Image(systemName: themePreference.systemImageName)
                    }
                    .accessibilityLabel(CoreStrings.accessibilityChangeAppearance)
                    .tint(.primary)
                }
            }
            .refreshable { await store.loadFirstPage() }
            .background(SharedUIAsset.background.swiftUIColor)
            .task { await store.loadPokemonsIfNeeded() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch store.listState {
        case .idle:
            LoadingView()
        case .loading where store.pokemons.isEmpty:
            LoadingView()
        case .error(let error) where store.pokemons.isEmpty:
            RetryView(message: messageFor(error)) {
                Task { await store.loadFirstPage() }
            }
            .accessibilityIdentifier("pokemon.list.retry")
        default:
            pokemonList
        }
    }

    // MARK: - List

    private var pokemonList: some View {
        // List uses UITableView under the hood → true cell reuse.
        // ScrollView+LazyVStack creates/destroys cells on every scroll-in/out,
        // which forces layout + shadow compositing for each cell appearance.
        List {
            ForEach(store.pokemons, id: \.id) { pokemon in
                Button {
                    onSelect(pokemon)
                } label: {
                    PokemonRowView(pokemon: pokemon)
                }
                .buttonStyle(PokemonCardButtonStyle())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .accessibilityIdentifier("pokemon.cell.\(pokemon.name.lowercased())")
                .accessibilityLabel("\(pokemon.name.capitalized), \(String(format: "#%03d", pokemon.id))")
                .task { await store.loadMoreIfNeeded(currentItem: pokemon) }
            }
            listFooter
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("pokemon.list.table")
        .background(SharedUIAsset.background.swiftUIColor)
    }

    @ViewBuilder
    private var listFooter: some View {
        if let error = store.pageError {
            // Inline retry — mirrors UIKit's RetryCell
            VStack(spacing: 8) {
                Text(messageFor(error))
                    .font(.footnote)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                    .multilineTextAlignment(.center)
                Button(CoreStrings.retryButtonTitle) {
                    Task { await store.retryPage() }
                }
                .font(.footnote)
                .accessibilityIdentifier("pokemon.list.retry.button")
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 56)
        } else if store.hasMore {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 56)
                .accessibilityLabel("Loading more Pokémon")
                .accessibilityIdentifier("pokemon.list.loading")
        }
    }

    // MARK: - Helpers

    private func messageFor(_ error: PokemonListError) -> String {
        switch error {
        case .noConnection: return CoreStrings.errorNoConnection
        case .unknown:      return CoreStrings.errorGenericLoading
        }
    }

    // MARK: - Notifications

    private func scheduleMewtwoNotification() async {
        guard await notificationScheduler.requestAuthorization() else { return }
        await notificationScheduler.schedule(
            LocalNotificationRequest(
                identifier: "pokemon.detail.151",
                title: CoreStrings.notificationDemoTitle,
                body: CoreStrings.notificationDemoBody,
                userInfo: ["pokemon_id": 151]
            )
        )
    }
}

// MARK: - Previews

private struct PreviewRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] {
        [
            Pokemon(id: 1, name: "bulbasaur", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png")),
            Pokemon(id: 4, name: "charmander", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png")),
            Pokemon(id: 7, name: "squirtle", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png")),
            Pokemon(id: 25, name: "pikachu", imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")),
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
    NavigationStack {
        PokemonListView(store: PokemonStore(repository: PreviewRepository()))
    }
}

#Preview("List – error") {
    NavigationStack {
        PokemonListView(store: PokemonStore(repository: ErrorRepository()))
    }
}
