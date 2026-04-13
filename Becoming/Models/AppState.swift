import SwiftUI
import Foundation

enum AccentColorOption: String, CaseIterable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case cyan = "Cyan"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case grey = "Grey"
    case white = "White"

    var swiftUIColor: Color {
        switch self {
        case .red: return Color(red: 0.902, green: 0.216, blue: 0.216) // #e63737
        case .orange: return Color(red: 0.902, green: 0.467, blue: 0.216) // #e67737
        case .yellow: return Color(red: 0.941, green: 0.769, blue: 0.290) // #f0c44a
        case .green: return Color(red: 0.396, green: 0.678, blue: 0.231) // #65ad3b
        case .cyan: return Color(red: 0.341, green: 0.851, blue: 0.851) // #57d9d9
        case .blue: return Color(red: 0.098, green: 0.565, blue: 0.902) // #1990e6
        case .purple: return Color(red: 0.427, green: 0.231, blue: 0.851) // #6d3bd9
        case .pink: return Color(red: 0.969, green: 0.486, blue: 0.686) // #f77caf
        case .grey: return Color(red: 0.529, green: 0.529, blue: 0.529) // #878787
        case .white: return Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff
        }
    }
}

struct AppTheme {
    let isDarkMode: Bool

    // Backgrounds
    var background: Color { isDarkMode ? Color(red: 0.06, green: 0.06, blue: 0.06) : Color.white }
    var secondaryBackground: Color { isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.97) }
    var cardBackground: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05) }

    // Text
    var textPrimary: Color { isDarkMode ? .white : .black }
    var textSecondary: Color { isDarkMode ? .gray : Color(red: 0.4, green: 0.4, blue: 0.4) }
    var textMuted: Color { isDarkMode ? .white.opacity(0.5) : .black.opacity(0.4) }

    // UI Elements
    var divider: Color { isDarkMode ? Color.gray.opacity(0.15) : Color.black.opacity(0.1) }
    var stroke: Color { isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08) }
    var overlay: Color { isDarkMode ? Color.black.opacity(0.6) : Color.black.opacity(0.4) }

    // Dotted line
    var dotColor: Color { isDarkMode ? Color.gray.opacity(0.15) : Color.black.opacity(0.12) }
}

class AppState: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var hasRecordedToday: Bool = false
    @Published var currentStreak: Int = 0
    @Published var notificationTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var userName: String = ""
    @Published var isDarkMode: Bool = true
    @Published var isLowercaseMode: Bool = false
    @Published var accentColor: AccentColorOption = .blue

    var theme: AppTheme { AppTheme(isDarkMode: isDarkMode) }
    
    init() {
        loadUserDefaults()
    }
    
    private func loadUserDefaults() {
        isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        hasRecordedToday = UserDefaults.standard.bool(forKey: "hasRecordedToday")
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        isLowercaseMode = UserDefaults.standard.bool(forKey: "isLowercaseMode")
        if let accentColorString = UserDefaults.standard.string(forKey: "accentColor"),
           let color = AccentColorOption(rawValue: accentColorString) {
            accentColor = color
        }
        // Default to dark mode if not set
        if !UserDefaults.standard.objectIsForced(forKey: "isDarkMode") {
            isDarkMode = true
        }
        
        if let timeData = UserDefaults.standard.data(forKey: "notificationTime"),
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            notificationTime = time
        }
    }
    
    func saveUserDefaults() {
        UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
        UserDefaults.standard.set(hasRecordedToday, forKey: "hasRecordedToday")
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(isLowercaseMode, forKey: "isLowercaseMode")
        UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor")
        
        if let timeData = try? JSONEncoder().encode(notificationTime) {
            UserDefaults.standard.set(timeData, forKey: "notificationTime")
        }
    }
    
    func completeOnboarding() {
        isOnboarded = true
        saveUserDefaults()
    }
    
    func recordedToday() {
        hasRecordedToday = true
        saveUserDefaults()
    }
}
