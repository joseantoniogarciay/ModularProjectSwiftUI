import Core
import SwiftUI

@main
struct ModularApp: App {
    #if DEV
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @AppStorage(ThemePreference.appStorageKey) private var themeRaw: String = ThemePreference.system.rawValue

    private var themePreference: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                pokemonStore: AppDependencies.shared.pokemonStore,
                accountStore: AppDependencies.shared.accountStore
            )
            .preferredColorScheme(themePreference.colorScheme)
        }
    }
}
