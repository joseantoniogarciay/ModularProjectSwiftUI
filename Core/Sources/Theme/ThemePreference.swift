public enum ThemePreference: String, Sendable {
    case system
    case light
    case dark

    public static let appStorageKey = "com.modular.swiftui.themePreference"

    public var next: ThemePreference {
        switch self {
        case .system: return .light
        case .light: return .dark
        case .dark: return .system
        }
    }

    public var systemImageName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}
