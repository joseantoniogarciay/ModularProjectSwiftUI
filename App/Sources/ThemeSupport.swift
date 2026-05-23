import Core
import SwiftUI

extension ThemePreference {
    /// Maps the stored preference to a SwiftUI color scheme.
    /// Returns `nil` for `.system` so SwiftUI follows the OS setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
