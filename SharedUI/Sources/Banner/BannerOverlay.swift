import SwiftUI

/// Renders the current banner from the environment `BannerPresenter` anchored to the top edge.
///
/// Apply once per presentation context: at the app root (covers all tab content) and, if a
/// banner must appear above a `.sheet`, on the sheet's content root too. Each context registers
/// itself with the presenter on appear; only the topmost one renders the banner, so an occluded
/// context keeps no `BannerView` in its hierarchy — no duplicate VoiceOver elements.
private struct BannerOverlayModifier: ViewModifier {
    @Environment(\.bannerPresenter) private var presenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Identifies this presentation context in the presenter's host registry.
    @State private var hostID = UUID()

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let presenter,
                   presenter.topmostHost == hostID,
                   let payload = presenter.current {
                    BannerView(payload: payload)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .id(payload.id)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity)
                        )
                        .onTapGesture { presenter.dismiss() }
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onEnded { value in
                                    if value.translation.height < -20 { presenter.dismiss() }
                                }
                        )
                }
            }
            .animation(
                reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8),
                value: presenter?.current?.id
            )
            .onAppear { presenter?.registerHost(hostID) }
            .onDisappear { presenter?.unregisterHost(hostID) }
    }
}

public extension View {
    /// Hosts the top-anchored banner overlay driven by the environment `BannerPresenter`.
    func bannerOverlay() -> some View {
        modifier(BannerOverlayModifier())
    }
}
