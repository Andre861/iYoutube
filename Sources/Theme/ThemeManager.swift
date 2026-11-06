import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "app_theme")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: saved) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .dark
        }
    }

    public func toggleTheme() {
        if selectedTheme == .dark {
            selectedTheme = .light
        } else {
            selectedTheme = .dark
        }
    }
}
