import SwiftUI
import UserNotifications

@main
struct BecomingApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var videoManager = VideoManager()
    @StateObject private var streakManager = StreakManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .environmentObject(videoManager)
                .environmentObject(streakManager)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        streakManager.checkDailyStreak()
    }
}
