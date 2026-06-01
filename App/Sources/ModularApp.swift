import Core
import SharedUI
import SwiftUI
#if DEV
import Pulse
#endif

@main
struct ModularApp: App {
    @AppStorage(ThemePreference.appStorageKey) private var themeRaw: String = ThemePreference.system.rawValue

    /// Owns the notification router for the app's lifetime. Its init registers the
    /// `UNUserNotificationCenter` delegate, mirroring the UIKit router created in `SceneDelegate`.
    @State private var notificationRouter = NotificationRouter()

    /// Drives the top-anchored banner overlay for the app's lifetime, mirroring the
    /// shared `BannerCenter` in the UIKit project.
    @State private var bannerPresenter = BannerPresenter()

    private var themePreference: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .system
    }

    init() {
        #if DEV
        // Was AppDelegate.didFinishLaunching — pure Pulse/Core setup, no UIKit needed here.
        LogCenter.loggers = [OSLogAppLogger(), PulseAppLogger()]
        URLSessionProxyDelegate.enableAutomaticRegistration()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                pokemonStore: AppDependencies.shared.pokemonStore,
                accountStore: AppDependencies.shared.accountStore,
                cartStore: AppDependencies.shared.cartStore,
                notificationRouter: notificationRouter
            )
            .environment(\.bannerPresenter, bannerPresenter)
            .environment(\.remoteImageLoader, .kingfisher)
            .preferredColorScheme(themePreference.colorScheme)
            .pulseConsole()
        }
    }
}
