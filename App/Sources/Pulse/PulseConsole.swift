import SwiftUI
#if DEV
import Combine
import CoreMotion
import PulseUI

/// Shake-to-open Pulse without UIKit. `CMMotionManager` watches the accelerometer and emits
/// a shake event when the combined acceleration spikes; the SwiftUI layer turns that into a
/// sheet hosting Pulse's `ConsoleView`. Replaces the old `UIWindow.motionEnded` override.
@MainActor
private final class ShakeDetector: ObservableObject {
    let shakes = PassthroughSubject<Void, Never>()

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private var lastShakeAt = Date.distantPast

    /// ~2.3g on the combined vector — high enough that normal handling doesn't trip it.
    private static let threshold = 2.3
    /// A single deliberate shake spans several samples; ignore repeats within this window.
    private static let debounce: TimeInterval = 1.0

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let acceleration = data?.acceleration else { return }
            let magnitude = (acceleration.x * acceleration.x
                + acceleration.y * acceleration.y
                + acceleration.z * acceleration.z).squareRoot()
            guard magnitude > Self.threshold else { return }
            Task { @MainActor in self?.registerShake() }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    private func registerShake() {
        let now = Date()
        guard now.timeIntervalSince(lastShakeAt) > Self.debounce else { return }
        lastShakeAt = now
        shakes.send()
    }
}

private struct PulseConsoleModifier: ViewModifier {
    @StateObject private var detector = ShakeDetector()
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onAppear { detector.start() }
            .onDisappear { detector.stop() }
            .onReceive(detector.shakes) { isPresented = true }
            .sheet(isPresented: $isPresented) {
                // ConsoleView expects an ambient NavigationStack and shows its own close button.
                NavigationStack { ConsoleView() }
            }
    }
}
#endif

extension View {
    /// Installs shake-to-open Pulse in DEV builds; a no-op everywhere else.
    func pulseConsole() -> some View {
        #if DEV
        modifier(PulseConsoleModifier())
        #else
        self
        #endif
    }
}
