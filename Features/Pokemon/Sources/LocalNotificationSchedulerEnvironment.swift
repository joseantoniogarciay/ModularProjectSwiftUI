import Core
import SwiftUI

/// Default scheduler used in previews and when the App layer hasn't injected a real one — does
/// nothing so previews never request permission or fire notifications.
private struct NoopLocalNotificationScheduler: LocalNotificationScheduling {
    func requestAuthorization() async -> Bool { false }
    func schedule(_ request: LocalNotificationRequest) async {}
}

private struct LocalNotificationSchedulerKey: EnvironmentKey {
    static let defaultValue: any LocalNotificationScheduling = NoopLocalNotificationScheduler()
}

public extension EnvironmentValues {
    var localNotificationScheduler: any LocalNotificationScheduling {
        get { self[LocalNotificationSchedulerKey.self] }
        set { self[LocalNotificationSchedulerKey.self] = newValue }
    }
}
