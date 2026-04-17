import SwiftUI

struct RecordsTabView: View {
    @Binding var benchWeight: Int
    @Binding var squatWeight: Int
    @Binding var deadliftWeight: Int
    @Binding var customWorkouts: [CustomWorkout]
    @Binding var showEditor: Bool
    @Binding var editingCategory: String
    @Binding var tempWeight: Double
    @Binding var showAddWorkout: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Lifts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("MAIN LIFTS")
                        .font(.system(size: 24, weight: .medium))
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        // Bench Max
                        PRCategoryRow(
                            category: "Bench",
                            weight: benchWeight,
                            onTap: {
                                HapticManager.shared.heavy()
                                editingCategory = "Bench"
                                tempWeight = Double(benchWeight)
                                showEditor = true
                            }
                        )
                        
                        // Squat Max
                        PRCategoryRow(
                            category: "Squat",
                            weight: squatWeight,
                            onTap: {
                                HapticManager.shared.heavy()
                                editingCategory = "Squat"
                                tempWeight = Double(squatWeight)
                                showEditor = true
                            }
                        )
                        
                        // Deadlift Max
                        PRCategoryRow(
                            category: "Deadlift",
                            weight: deadliftWeight,
                            onTap: {
                                HapticManager.shared.heavy()
                                editingCategory = "Deadlift"
                                tempWeight = Double(deadliftWeight)
                                showEditor = true
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                // Custom Workouts Section
                if !customWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CUSTOM WORKOUTS")
                            .font(.system(size: 24, weight: .medium))
                            .fontWidth(.expanded)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(customWorkouts) { workout in
                                PRCategoryRow(
                                    category: workout.name,
                                    weight: workout.weight,
                                    onTap: {
                                        HapticManager.shared.heavy()
                                        editingCategory = workout.name
                                        tempWeight = Double(workout.weight)
                                        showEditor = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Add Workout Button
                VStack(spacing: 16) {
                    Button(action: {
                        showAddWorkout = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
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
