import SwiftUI

/// Drives the top-anchored banner overlay. Inject one instance at the app root and read it
/// from any view via `@Environment(\.bannerPresenter)`; the overlay is rendered once by
/// `.bannerOverlay()`. Plays the role of UIKit's `BannerCenter`, minus the dedicated window —
/// in SwiftUI the overlay lives in the host view's hierarchy.
@MainActor
@Observable
public final class BannerPresenter {
    public private(set) var current: BannerPayload?

    private var dismissTask: Task<Void, Never>?

    /// Registered overlay hosts in appearance order. The last one is the topmost
    /// presentation context (e.g. a `.sheet` presented over the root), so only it
    /// renders the banner — the occluded contexts stay out of the view hierarchy
    /// entirely, avoiding duplicate VoiceOver elements.
    private var hosts: [UUID] = []

    /// The host that was topmost when the current banner was shown. The banner belongs
    /// to that context: if it disappears (e.g. its `.sheet` is dismissed), the banner is
    /// dismissed with it rather than re-surfacing on the context behind — which would look
    /// like the banner suddenly popping back in for its remaining time.
    private var owningHost: UUID?

    public init() {}

    public func show(_ payload: BannerPayload) {
        dismissTask?.cancel()
        owningHost = topmostHost
        current = payload

        let duration = payload.duration
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        owningHost = nil
        current = nil
    }

    // MARK: - Host registry

    var topmostHost: UUID? { hosts.last }

    func registerHost(_ id: UUID) {
        hosts.removeAll { $0 == id }
        hosts.append(id)
    }

    func unregisterHost(_ id: UUID) {
        hosts.removeAll { $0 == id }
        if id == owningHost { dismiss() }
    }
}

private struct BannerPresenterKey: EnvironmentKey {
    static let defaultValue: BannerPresenter? = nil
}

public extension EnvironmentValues {
    var bannerPresenter: BannerPresenter? {
        get { self[BannerPresenterKey.self] }
        set { self[BannerPresenterKey.self] = newValue }
    }
}
