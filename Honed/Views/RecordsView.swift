import SwiftUI
import Foundation

struct RecordsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    
    @State private var benchWeight = 135
    @State private var squatWeight = 135
    @State private var deadliftWeight = 135
    
    @State private var showEditor = false
    @State private var editingCategory = ""
    @State private var tempWeight: Double = 135
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PR Categories
                    VStack(spacing: 32) {
                        // Bench Max
                        PRCategoryRow(
                            category: "Bench",
                            weight: benchWeight,
                            onTap: {
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
                                editingCategory = "Deadlift"
                                tempWeight = Double(deadliftWeight)
                                showEditor = true
                            }
                        )
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEditor) {
            WeightEditorSheet(
                category: editingCategory,
                weight: $tempWeight,
                onSave: {
                    let roundedWeight = Int((tempWeight / 5).rounded() * 5)
                    switch editingCategory {
                    case "Bench": benchWeight = roundedWeight
                    case "Squat": squatWeight = roundedWeight
                    case "Deadlift": deadliftWeight = roundedWeight
                    default: break
                    }
                    showEditor = false
                },
                onCancel: {
                    showEditor = false
                }
            )
            .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
            .presentationDragIndicator(Visibility.visible)
        }
    }
}

struct PRCategoryRow: View {
    let category: String
    let weight: Int
    let onTap: () -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.uppercased())
                    .font(.system(size: 18, weight: .regular))
                    .fontWidth(.expanded)
                    .foregroundColor(appState.theme.textSecondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(weight)")
                        .font(.system(size: 64, weight: .bold))
                        .fontWidth(.expanded)
                        .foregroundColor(appState.theme.textPrimary)
                    
                    Text("lbs")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(appState.theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeightEditorSheet: View {
    let category: String
    @Binding var weight: Double
    let onSave: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var appState: AppState
    
    @State private var previousRoundedWeight: Int = 0
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                // Fade gradient from bottom (starts at middle, fades up)
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            appState.theme.background.opacity(0.0),
                            appState.theme.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height / 2)
                }
                .ignoresSafeArea()
                
                // Placeholder image at top with gradient fade
                VStack {
                    ZStack {
                        Rectangle()
                            .fill(appState.theme.cardBackground)
                            .frame(height: geometry.size.height * 0.75)
                        
                        // Gradient fade at bottom of image
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [
                                    appState.theme.cardBackground,
                                    appState.theme.cardBackground.opacity(0.5),
                                    appState.theme.background
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: geometry.size.height * 0.60)
                        }
                        .frame(height: geometry.size.height * 0.75)
                        
                        // Icon
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 80))
                            .foregroundColor(appState.theme.textMuted)
                            .padding(.top, geometry.size.height * 0.05)
                    }
                    
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                
                // Content moved down to bottom half
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Category Title
                    Text(category.uppercased())
                        .font(.system(size: 24, weight: .regular))
                        .fontWidth(.expanded)
                        .foregroundColor(appState.theme.textSecondary)
                    
                    Spacer().frame(height: 24)
                    
                    // Weight Display
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("\(Int((weight / 5).rounded() * 5))")
                            .font(.system(size: 80, weight: .bold))
                            .fontWidth(.expanded)
                            .foregroundColor(appState.theme.textPrimary)
                        
                        Text("lbs")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(appState.theme.textMuted)
                    }
                    
                    Spacer().frame(height: 42)
                    
                    // Slider
                    VStack(spacing: 16) {
                        Slider(
                            value: $weight,
                            in: 5...495,
                            step: 5
                        )
                        .tint(appState.accentColor.swiftUIColor)
                        .onChange(of: weight) { newValue in
                            let rounded = Int((newValue / 5).rounded() * 5)
                            if rounded != previousRoundedWeight {
                                feedbackGenerator.impactOccurred()
                                previousRoundedWeight = rounded
                            }
                        }
                        .onAppear {
                            previousRoundedWeight = Int((weight / 5).rounded() * 5)
                            feedbackGenerator.prepare()
                        }
                        
                        HStack {
                            Text("5 lbs")
                                .font(.system(size: 14))
                                .foregroundColor(appState.theme.textMuted)
                            Spacer()
                            Text("495 lbs")
                                .font(.system(size: 14))
                            .foregroundColor(appState.theme.textMuted)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(appState.theme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .foregroundColor(appState.accentColor.swiftUIColor)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            }
        }
    }
}

#Preview {
    RecordsView()
        .environmentObject(AppState())
        .environmentObject(CalendarManager())
}
