import Core
import Foundation
import UserNotifications

/// SwiftUI replacement for the UIKit `PushNotificationRouter`.
///
/// Registers itself as the `UNUserNotificationCenter` delegate on init — mirroring the
/// UIKit router that `SceneDelegate` created on scene connection. When the user taps a
/// notification carrying a `pokemon_id`, it publishes a `PokemonDeepLink`; `RootView`
/// observes that value and presents the Pokémon detail modally, the SwiftUI analogue of
/// the UIKit router's `present(_:animated:)`.
///
/// The two delegate callbacks are `nonisolated` (the protocol requirements are), so they
/// hop back to the main actor via `Task { @MainActor }` before mutating observable state,
/// exactly as the UIKit implementation did.
@MainActor
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    var deepLink: PokemonDeepLink?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    private func present(pokemonID: Int) {
        let imageURL = URL(
            string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(pokemonID).png"
        )
        deepLink = PokemonDeepLink(pokemon: Pokemon(id: pokemonID, name: "", imageURL: imageURL))
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let id = userInfo["pokemon_id"] as? Int
        Task { @MainActor [weak self] in
            if let id { self?.present(pokemonID: id) }
            completionHandler()
        }
    }
}

/// Identifiable wrapper so a deep-linked Pokémon can drive `.sheet(item:)`.
///
/// Kept in the App layer on purpose: it avoids widening `Core.Pokemon`'s public API with
/// an `Identifiable` conformance that only this deep-link sheet would consume.
struct PokemonDeepLink: Identifiable {
    let pokemon: Pokemon
    var id: Int { pokemon.id }
}
