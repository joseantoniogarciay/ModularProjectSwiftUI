#if DEV
import Core
import Pulse
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        LogCenter.loggers = [OSLogAppLogger(), PulseAppLogger()]
        URLSessionProxyDelegate.enableAutomaticRegistration()
        return true
    }
}
#endif
