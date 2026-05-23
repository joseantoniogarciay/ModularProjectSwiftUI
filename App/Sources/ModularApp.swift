import Core
import Pokemon
import SwiftUI

@main
struct ModularApp: App {
    @AppStorage(ThemePreference.appStorageKey) private var themeRaw: String = ThemePreference.system.rawValue

    private var themePreference: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            PokemonListView(store: AppDependencies.shared.pokemonStore)
                .preferredColorScheme(themePreference.colorScheme)
        }
    }
}
