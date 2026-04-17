import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Charts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("STRENGTH PROGRESS")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    // Mock Progress Chart
                    ProgressChartView()
                        .padding(.horizontal, 24)
                }
                
                // Recent PRs Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("RECENT PRs")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        RecentPRRow(exercise: "Bench Press", weight: 135, date: "2 days ago", isNew: true)
                        RecentPRRow(exercise: "Squat", weight: 135, date: "1 week ago", isNew: false)
                        RecentPRRow(exercise: "Deadlift", weight: 135, date: "2 weeks ago", isNew: false)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("THIS MONTH")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 16) {
                        StatCard(title: "Workouts", value: "12", subtitle: "+3 from last month")
                        StatCard(title: "Total Volume", value: "24.5K", subtitle: "lbs moved")
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 120)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }
}
