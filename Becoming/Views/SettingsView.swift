import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Notification Settings
                        SettingsSection(title: "Notifications") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Daily reminder")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    DatePicker("", selection: $appState.notificationTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                
                                Toggle("One take mode", isOn: $appState.oneTakeMode)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Stats Section
                        SettingsSection(title: "Your journey") {
                            VStack(spacing: 16) {
                                StatRow(label: "Current streak", value: "\(streakManager.currentStreak) days")
                                StatRow(label: "Longest streak", value: "\(streakManager.longestStreak) days")
                                StatRow(label: "Consistency tier", value: streakManager.consistencyTier)
                            }
                        }
                        
                        // About Section
                        SettingsSection(title: "About") {
                            VStack(spacing: 16) {
                                InfoRow(label: "Version", value: "1.0.0")
                                InfoRow(label: "Build", value: "1")
                            }
                        }
                        
                        // Reset Section
                        SettingsSection(title: "Reset") {
                            VStack(spacing: 16) {
                                Button("Reset Streak") {
                                    resetStreak()
                                }
                                .foregroundColor(.red)
                                
                                Button("Reset All Data") {
                                    resetAllData()
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .onChange(of: appState.notificationTime) { newTime in
            notificationManager.scheduleDailyNotification(at: newTime, streak: streakManager.currentStreak)
        }
        .onChange(of: appState.oneTakeMode) { _ in
            appState.saveUserDefaults()
        }
    }
    
    private func resetStreak() {
        streakManager.currentStreak = 0
        streakManager.lastRecordingDate = nil
    }
    
    private func resetAllData() {
        // Reset all user defaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "isOnboarded")
        defaults.removeObject(forKey: "hasRecordedToday")
        defaults.removeObject(forKey: "currentStreak")
        defaults.removeObject(forKey: "longestStreak")
        defaults.removeObject(forKey: "lastRecordingDate")
        defaults.removeObject(forKey: "notificationTime")
        defaults.removeObject(forKey: "oneTakeMode")
        defaults.removeObject(forKey: "videoEntries")
        
        // Reset app state
        appState.isOnboarded = false
        appState.hasRecordedToday = false
        appState.currentStreak = 0
        
        // Reset managers
        streakManager.currentStreak = 0
        streakManager.longestStreak = 0
        streakManager.lastRecordingDate = nil
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                content
            }
            .padding(20)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(24)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
        .environmentObject(StreakManager())
}
