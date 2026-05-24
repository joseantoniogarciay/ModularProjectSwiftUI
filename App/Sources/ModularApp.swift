import Core
import SwiftUI

@main
struct ModularApp: App {
    #if DEV
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @AppStorage(ThemePreference.appStorageKey) private var themeRaw: String = ThemePreference.system.rawValue

    /// Owns the notification router for the app's lifetime. Its init registers the
    /// `UNUserNotificationCenter` delegate, mirroring the UIKit router created in `SceneDelegate`.
    @State private var notificationRouter = NotificationRouter()

    private var themePreference: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                pokemonStore: AppDependencies.shared.pokemonStore,
                accountStore: AppDependencies.shared.accountStore,
                cartStore: AppDependencies.shared.cartStore,
                notificationRouter: notificationRouter
            )
            .preferredColorScheme(themePreference.colorScheme)
        }
    }
}
