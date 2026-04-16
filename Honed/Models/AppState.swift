import SwiftUI
import Combine

enum AccentColorOption: String, CaseIterable {
    case lime = "Lime"
    
    var swiftUIColor: Color {
        // Fixed accent color: #ADF93A
        Color(red: 0.678, green: 0.976, blue: 0.227)
    }
}

struct AppTheme {
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let dotColor: Color
    let stroke: Color
    let isDarkMode: Bool
    
    static var light: AppTheme {
        AppTheme(
            background: Color(red: 0.95, green: 0.95, blue: 0.97),
            cardBackground: Color.white,
            textPrimary: Color.black,
            textSecondary: Color.gray,
            textMuted: Color.gray.opacity(0.6),
            dotColor: Color.gray.opacity(0.3),
            stroke: Color.gray.opacity(0.2),
            isDarkMode: false
        )
    }
    
    static var dark: AppTheme {
        AppTheme(
            background: Color(red: 0, green: 0, blue: 0),
            cardBackground: Color(red: 0.1, green: 0.1, blue: 0.1),
            textPrimary: Color.white,
            textSecondary: Color.gray,
            textMuted: Color.gray.opacity(0.6),
            dotColor: Color.gray.opacity(0.3),
            stroke: Color.gray.opacity(0.2),
            isDarkMode: true
        )
    }
}

class AppState: ObservableObject {
    @Published var isOnboarded: Bool {
        didSet { saveUserDefaults() }
    }
    @Published var isDarkMode: Bool {
        didSet { saveUserDefaults() }
    }
    @Published var accentColor: AccentColorOption = .lime
    @Published var userName: String {
        didSet { saveUserDefaults() }
    }
    @Published var notificationTime: Date {
        didSet { saveUserDefaults() }
    }
    
    var theme: AppTheme {
        isDarkMode ? .dark : .light
    }
    
    init() {
        let defaults = UserDefaults.standard
        self.isOnboarded = defaults.bool(forKey: "isOnboarded")
        
        // Default to dark mode if not set
        if defaults.object(forKey: "isDarkMode") == nil {
            self.isDarkMode = true
        } else {
            self.isDarkMode = defaults.bool(forKey: "isDarkMode")
        }
        
        // Accent color is fixed to lime green
        self.userName = defaults.string(forKey: "userName") ?? ""
        
        if let timeData = defaults.object(forKey: "notificationTime") as? Date {
            self.notificationTime = timeData
        } else {
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            self.notificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    func saveUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isOnboarded, forKey: "isOnboarded")
        defaults.set(isDarkMode, forKey: "isDarkMode")
        defaults.set(userName, forKey: "userName")
        defaults.set(notificationTime, forKey: "notificationTime")
    }
}
