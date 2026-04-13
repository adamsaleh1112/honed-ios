import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var videoManager: VideoManager
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Settings
                        SettingsSection(title: "Profile") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "person")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 28)
                                    Text(appState.isLowercaseMode ? "Your name".lowercased() : "Your name")
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)
                                    Spacer()
                                    TextField("Enter name", text: $appState.userName)
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: 150)
                                }
                                
                                NavigationLink(destination: YourJourneyView()) {
                                    HStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 18))
                                            .foregroundColor(.gray)
                                            .frame(width: 28)
                                        Text(appState.isLowercaseMode ? "Your journey".lowercased() : "Your journey")
                                            .font(.system(size: 16))
                                            .foregroundColor(appState.theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Appearance Settings
                        SettingsSection(title: "Appearance") {
                            VStack(spacing: 14) {
                                // Theme selector
                                HStack(spacing: 12) {
                                    Text(appState.isLowercaseMode ? "Theme".lowercased() : "Theme")
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)

                                    Spacer()

                                    // Capsule icon toggle
                                    HStack(spacing: 0) {
                                        // Light button (sun icon)
                                        Button(action: {
                                            appState.isDarkMode = false
                                            appState.saveUserDefaults()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(!appState.isDarkMode ? appState.accentColor.swiftUIColor : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "sun.max.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(!appState.isDarkMode ? .white : appState.theme.textSecondary)
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        // Dark button (moon icon)
                                        Button(action: {
                                            appState.isDarkMode = true
                                            appState.saveUserDefaults()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(appState.isDarkMode ? appState.accentColor.swiftUIColor : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "moon.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(appState.isDarkMode ? .white : appState.theme.textSecondary)
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(2)
                                    .background(appState.theme.cardBackground)
                                    .clipShape(Capsule())
                                }

                                // Casing selector
                                HStack(spacing: 12) {
                                    Text(appState.isLowercaseMode ? "Casing".lowercased() : "Casing")
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)

                                    Spacer()

                                    // Capsule icon toggle
                                    HStack(spacing: 0) {
                                        // Default button (textformat.characters icon)
                                        Button(action: {
                                            appState.isLowercaseMode = false
                                            appState.saveUserDefaults()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(!appState.isLowercaseMode ? appState.accentColor.swiftUIColor : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "textformat.characters")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(!appState.isLowercaseMode ? .white : appState.theme.textSecondary)
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        // Lowercase button (characters.lowercase icon)
                                        Button(action: {
                                            appState.isLowercaseMode = true
                                            appState.saveUserDefaults()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(appState.isLowercaseMode ? appState.accentColor.swiftUIColor : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "characters.lowercase")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(appState.isLowercaseMode ? .white : appState.theme.textSecondary)
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(2)
                                    .background(appState.theme.cardBackground)
                                    .clipShape(Capsule())
                                }
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 28)
                                    Text(appState.isLowercaseMode ? "Accent color".lowercased() : "Accent color")
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)
                                    Spacer()
                                    Picker("Accent Color", selection: $appState.accentColor) {
                                        ForEach(AccentColorOption.allCases, id: \.self) { color in
                                            HStack {
                                                Circle()
                                                    .fill(color.swiftUIColor)
                                                    .frame(width: 12, height: 12)
                                                Text(color.rawValue)
                                            }
                                            .tag(color)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(appState.accentColor.swiftUIColor)
                                }
                            }
                        }
                        
                        // Notification Settings
                        SettingsSection(title: "Notifications") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 28)
                                    Text(appState.isLowercaseMode ? "Daily reminder".lowercased() : "Daily reminder")
                                        .font(.system(size: 16))
                                        .foregroundColor(appState.theme.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: $appState.notificationTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .environment(\.colorScheme, appState.isDarkMode ? .dark : .light)
                                }
                            }
                        }
                        
                        
                        // About Section
                        SettingsSection(title: "About") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 28)
                                    InfoRow(label: appState.isLowercaseMode ? "Version".lowercased() : "Version", value: "1.0.0")
                                }
                                HStack {
                                    Image(systemName: "number")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 28)
                                    InfoRow(label: appState.isLowercaseMode ? "Build".lowercased() : "Build", value: "1")
                                }
                            }
                        }
                        
                        // Reset Section
                        SettingsSection(title: "Reset") {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                        .frame(width: 28)
                                    Button(appState.isLowercaseMode ? "Reset Streak".lowercased() : "Reset Streak") {
                                        resetStreak()
                                    }
                                    .foregroundColor(.red)
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                        .frame(width: 28)
                                    Button(appState.isLowercaseMode ? "Reset All Data".lowercased() : "Reset All Data") {
                                        resetAllData()
                                    }
                                    .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: appState.notificationTime) { newTime in
            notificationManager.scheduleDailyNotification(at: newTime, streak: streakManager.currentStreak, userName: appState.userName)
        }
        .onChange(of: appState.userName) { _ in
            appState.saveUserDefaults()
            notificationManager.scheduleDailyNotification(at: appState.notificationTime, streak: streakManager.currentStreak, userName: appState.userName)
        }
        .onChange(of: appState.isDarkMode) { _ in
            appState.saveUserDefaults()
        }
        .onChange(of: appState.isLowercaseMode) { _ in
            appState.saveUserDefaults()
        }
        .onChange(of: appState.accentColor) { _ in
            appState.saveUserDefaults()
        }
    }
    
    private func resetStreak() {
        streakManager.currentStreak = 0
        streakManager.lastRecordingDate = nil
    }
    
    private func resetAllData() {
        // Delete all videos and thumbnails
        videoManager.resetAllVideos()
        
        // Reset all user defaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "isOnboarded")
        defaults.removeObject(forKey: "hasRecordedToday")
        defaults.removeObject(forKey: "currentStreak")
        defaults.removeObject(forKey: "longestStreak")
        defaults.removeObject(forKey: "lastRecordingDate")
        defaults.removeObject(forKey: "notificationTime")
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
    @EnvironmentObject var appState: AppState

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appState.isLowercaseMode ? title.lowercased() : title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(appState.theme.textPrimary)

            VStack(spacing: 12) {
                content
            }
            .padding(20)
            .background(appState.theme.cardBackground)
            .cornerRadius(24)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(appState.theme.textPrimary)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(appState.theme.textPrimary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
        .environmentObject(StreakManager())
        .environmentObject(VideoManager())
}
