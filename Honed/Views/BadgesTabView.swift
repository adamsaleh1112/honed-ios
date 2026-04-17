import SwiftUI

struct BadgesTabView: View {
    let benchWeight: Int
    let squatWeight: Int
    let deadliftWeight: Int
    @EnvironmentObject var appState: AppState
    
    @State private var selectedBadge: Badge?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Achievement Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACHIEVEMENTS")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 16) {
                        StatCard(title: "Earned", value: "\(earnedBadges.count)", subtitle: "badges unlocked")
                        
                        let earnedCount = Double(earnedBadges.count)
                        let totalCount = Double(allBadges.count)
                        let progressPercentage = Int((earnedCount / totalCount) * 100)
                        
                        StatCard(title: "Progress", value: "\(progressPercentage)%", subtitle: "completion")
                    }
                    .padding(.horizontal, 24)
                }
                
                // Badges Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("MILESTONE BADGES")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(allBadges, id: \.id) { badge in
                            BadgeCard(
                                badge: badge,
                                isEarned: earnedBadges.contains { $0.id == badge.id }
                            )
                            .onTapGesture {
                                HapticManager.shared.soft()
                                selectedBadge = badge
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Share Section
                VStack(spacing: 16) {
                    Button(action: {
                        // TODO: Implement sharing
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                            Text("Share Gym Profile")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(appState.accentColor.swiftUIColor)
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 120)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(
                badge: badge,
                isEarned: earnedBadges.contains { $0.id == badge.id }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var earnedBadges: [Badge] {
        allBadges.filter { badge in
            switch badge.requirement {
            case .benchPress(let weight):
                return benchWeight >= weight
            case .squat(let weight):
                return squatWeight >= weight
            case .deadlift(let weight):
                return deadliftWeight >= weight
            case .total(let weight):
                return (benchWeight + squatWeight + deadliftWeight) >= weight
            }
        }
    }
    
    private var allBadges: [Badge] {
        [
            Badge(id: "bench_100", title: "Century Club", subtitle: "Bench 100+ lbs", icon: "💪", requirement: .benchPress(100)),
            Badge(id: "bench_135", title: "Plate Club", subtitle: "Bench 135+ lbs", icon: "🏋️", requirement: .benchPress(135)),
            Badge(id: "bench_200", title: "Two Plates", subtitle: "Bench 200+ lbs", icon: "🔥", requirement: .benchPress(200)),
            Badge(id: "squat_135", title: "Squat Starter", subtitle: "Squat 135+ lbs", icon: "🦵", requirement: .squat(135)),
            Badge(id: "squat_225", title: "Squat Strong", subtitle: "Squat 225+ lbs", icon: "💎", requirement: .squat(225)),
            Badge(id: "deadlift_135", title: "Off the Ground", subtitle: "Deadlift 135+ lbs", icon: "⚡", requirement: .deadlift(135)),
            Badge(id: "deadlift_315", title: "Three Plates", subtitle: "Deadlift 315+ lbs", icon: "👑", requirement: .deadlift(315)),
            Badge(id: "total_500", title: "Half Ton", subtitle: "500+ lb total", icon: "🏆", requirement: .total(500))
        ]
    }
}
