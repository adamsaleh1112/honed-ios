import SwiftUI
import Foundation

enum AccentColorOption: String, CaseIterable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case gray = "Gray"
    
    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .gray: return .gray
        }
    }
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
