import SwiftUI

struct YourJourneyView: View {
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var appState: AppState
    
    // Computed properties for statistics
    private var totalVideoEntries: Int {
        videoManager.videoEntries.count
    }
    
    private var perfectDays: Int {
        videoManager.videoEntries.filter { $0.rating == 10 }.count
    }
    
    private var goodDays: Int {
        videoManager.videoEntries.filter { 
            if let rating = $0.rating {
                return rating >= 7 && rating <= 9
            }
            return false
        }.count
    }
    
    private var midDays: Int {
        videoManager.videoEntries.filter { 
            if let rating = $0.rating {
                return rating >= 5 && rating <= 6
            }
            return false
        }.count
    }
    
    private var badDays: Int {
        videoManager.videoEntries.filter { 
            if let rating = $0.rating {
                return rating >= 1 && rating <= 4
            }
            return false
        }.count
    }
    
    private var dateStarted: String {
        guard let firstEntry = videoManager.videoEntries.last else {
            return "Not started yet"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: firstEntry.date)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Journey Overview
                    SettingsSection(title: "Journey Overview") {
                        VStack(spacing: 16) {
                            JourneyStatRow(
                                icon: "video.fill",
                                iconColor: .blue,
                                label: "Video entries",
                                value: "\(totalVideoEntries)"
                            )
                            
                            JourneyStatRow(
                                icon: "calendar",
                                iconColor: .gray,
                                label: "Date started",
                                value: dateStarted
                            )
                        }
                    }
                    
                    // Rating Breakdown
                    SettingsSection(title: "Rating Breakdown") {
                        VStack(spacing: 16) {
                            JourneyStatRow(
                                icon: "star.fill",
                                iconColor: .green,
                                label: "Perfect days (10)",
                                value: "\(perfectDays)"
                            )
                            
                            JourneyStatRow(
                                icon: "hand.thumbsup.fill",
                                iconColor: .yellow,
                                label: "Good days (7-9)",
                                value: "\(goodDays)"
                            )
                            
                            JourneyStatRow(
                                icon: "minus.circle.fill",
                                iconColor: .orange,
                                label: "Mid days (5-6)",
                                value: "\(midDays)"
                            )
                            
                            JourneyStatRow(
                                icon: "hand.thumbsdown.fill",
                                iconColor: .red,
                                label: "Bad days (1-4)",
                                value: "\(badDays)"
                            )
                        }
                    }
                    
                    // Streak Statistics
                    SettingsSection(title: "Streak Statistics") {
                        VStack(spacing: 16) {
                            JourneyStatRow(
                                icon: "flame.fill",
                                iconColor: .orange,
                                label: "Current streak",
                                value: "\(streakManager.currentStreak) days"
                            )
                            
                            JourneyStatRow(
                                icon: "trophy.fill",
                                iconColor: .yellow,
                                label: "Longest streak",
                                value: "\(streakManager.longestStreak) days"
                            )
                        }
                    }
                    
                    // Motivational Section
                    if totalVideoEntries > 0 {
                        SettingsSection(title: "Your Progress") {
                            VStack(spacing: 12) {
                                Text(streakManager.motivationalMessage)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(appState.isLowercaseMode ? "Consistency Tier: \(streakManager.consistencyTier)".lowercased() : "Consistency Tier: \(streakManager.consistencyTier)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Your Journey")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct JourneyStatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            Text(appState.isLowercaseMode ? label.lowercased() : label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        YourJourneyView()
            .environmentObject(VideoManager())
            .environmentObject(StreakManager())
    }
}
