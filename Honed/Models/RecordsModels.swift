import Foundation

// MARK: - Custom Workout
struct CustomWorkout: Identifiable {
    let id: String
    let name: String
    var weight: Int
}

// MARK: - Badge
struct Badge: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let requirement: BadgeRequirement
}

enum BadgeRequirement {
    case benchPress(Int)
    case squat(Int)
    case deadlift(Int)
    case total(Int)
}
