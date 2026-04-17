import SwiftUI
import Foundation
import UIKit

struct RecordsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    
    @State private var selectedTab = 0
    @State private var benchWeight = 135
    @State private var squatWeight = 135
    @State private var deadliftWeight = 135
    @State private var customWorkouts: [CustomWorkout] = []
    
    @State private var showEditor = false
    @State private var editingCategory = ""
    @State private var tempWeight: Double = 135
    @State private var showAddWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                ZStack(alignment: .top) {
                    // Tab Content (behind tab bar)
                    TabView(selection: $selectedTab) {
                        // Records Tab
                        RecordsTabView(
                            benchWeight: $benchWeight,
                            squatWeight: $squatWeight,
                            deadliftWeight: $deadliftWeight,
                            customWorkouts: $customWorkouts,
                            showEditor: $showEditor,
                            editingCategory: $editingCategory,
                            tempWeight: $tempWeight,
                            showAddWorkout: $showAddWorkout
                        )
                        .tag(0)
                        
                        // Progress Tab
                        ProgressTabView()
                            .tag(1)
                        
                        // Badges Tab
                        BadgesTabView(
                            benchWeight: benchWeight,
                            squatWeight: squatWeight,
                            deadliftWeight: deadliftWeight
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea(.container, edges: .bottom)
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                    
                    // Custom Tab Bar (completely in front)
                    VStack {
                        CustomTabBar(selectedTab: $selectedTab)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            .background(
                                LinearGradient(
                                    colors: [
                                        appState.theme.background,
                                        appState.theme.background.opacity(0.8),
                                        appState.theme.background.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Spacer()
                    }
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
                    default:
                        // Handle custom workout updates
                        if let index = customWorkouts.firstIndex(where: { $0.name == editingCategory }) {
                            customWorkouts[index].weight = roundedWeight
                        }
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
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutSheet(
                onSave: { workoutName in
                    let newWorkout = CustomWorkout(id: UUID().uuidString, name: workoutName, weight: 135)
                    customWorkouts.append(newWorkout)
                    showAddWorkout = false
                },
                onCancel: {
                    showAddWorkout = false
                }
            )
            .presentationDetents([PresentationDetent.medium])
            .presentationDragIndicator(Visibility.visible)
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState
    @Namespace private var animation
    
    let tabs = ["RECORDS", "PROGRESS", "BADGES"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        DispatchQueue.main.async {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 0) {
                            Text(tabs[index])
                                .font(.system(size: 20, weight: selectedTab == index ? .semibold : .medium))
                                .fontWidth(.compressed)
                                .foregroundColor(selectedTab == index ? appState.theme.textPrimary : appState.theme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // Animated indicator
            GeometryReader { geometry in
                let tabWidth = geometry.size.width / CGFloat(tabs.count)
                let indicatorOffset = CGFloat(selectedTab) * tabWidth + (tabWidth - 40) / 2
                
                Rectangle()
                    .fill(appState.accentColor.swiftUIColor)
                    .frame(width: 40, height: 3)
                    .offset(x: indicatorOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
            }
            .frame(height: 3)
        }
        .padding(.bottom, 20)
    }
}

struct PRCategoryRow: View {
    let category: String
    let weight: Int
    let onTap: () -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Weight image in back - not clickable
            WeightImageView(weight: weight)
                .frame(width: 140, height: 140)
                .offset(x: 0)
            
            // Text content in front
            VStack(alignment: .leading, spacing: 0) {
                // Category label is NOT clickable
                Text(category.uppercased())
                    .font(.system(size: 18, weight: .regular))
                    .fontWidth(.expanded)
                    .foregroundColor(appState.theme.textSecondary)
                
                // Only the weight text is clickable
                Button(action: onTap) {
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
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.leading, 140)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .onAppear {
                        previousRoundedWeight = Int((weight / 5).rounded() * 5)
                        feedbackGenerator.prepare()
                    }
                
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
                    
                    Spacer().frame(height: 8)
                    
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

struct WeightImageView: View {
    let weight: Int
    @State private var isLoading = true
    @State private var loadError: String?
    
    private var imageURL: String {
        let imageWeight = determineImageWeight(for: weight)
        // For private buckets, we need to use signed URLs or make the bucket public
        // Option 1: Use signed URL endpoint (requires backend to generate)
        // return "https://tzkgjsfuvgnajpayeagb.supabase.co/storage/v1/object/sign/assets/images/weights/\(imageWeight).png"
        
        // Option 2: Try public URL first (in case you make bucket public)
        return "https://tzkgjsfuvgnajpayeagb.supabase.co/storage/v1/object/public/assets/images/weights/\(imageWeight).png"
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(let error):
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.2))
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Error")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    )
                    .onAppear {
                        loadError = error.localizedDescription
                        print("❌ Image load error for weight \(weight): \(error)")
                        print("🔗 Attempted URL: \(imageURL)")
                    }
            case .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "dumbbell")
                                    .foregroundColor(.gray)
                            }
                        }
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .onAppear {
            print("🔍 Loading image for weight: \(weight)")
            print("🔗 URL: \(imageURL)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isLoading = false
            }
        }
    }
    
    private func determineImageWeight(for weight: Int) -> Int {
        let weightIntervals = [0, 30, 45, 75, 95, 115, 135, 165, 185, 205, 225, 255, 275, 295, 305]
        
        // Find the highest interval that the weight exceeds
        var selectedWeight = 45 // Default to lowest
        
        for interval in weightIntervals {
            if weight >= interval {
                selectedWeight = interval
            }
        }
        
        return selectedWeight
    }
}

// MARK: - Supporting Components

struct ProgressChartView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(appState.theme.cardBackground)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(appState.theme.textMuted)
                        Text("Progress Chart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(appState.theme.textMuted)
                        Text("Coming Soon")
                            .font(.system(size: 14))
                            .foregroundColor(appState.theme.textSecondary)
                    }
                )
        }
    }
}

struct RecentPRRow: View {
    let exercise: String
    let weight: Int
    let date: String
    let isNew: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(appState.theme.textPrimary)
                    
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(appState.accentColor.swiftUIColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appState.accentColor.swiftUIColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(date)
                    .font(.system(size: 14))
                    .foregroundColor(appState.theme.textSecondary)
            }
            
            Spacer()
            
            Text("\(weight) lbs")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(appState.theme.textPrimary)
        }
        .padding(16)
        .background(appState.theme.cardBackground)
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(appState.theme.textSecondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(appState.theme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(appState.theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(appState.theme.cardBackground)
        .cornerRadius(12)
    }
}

struct BadgeCard: View {
    let badge: Badge
    let isEarned: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 12) {
            Text(badge.icon)
                .font(.system(size: 36))
                .opacity(isEarned ? 1.0 : 0.3)
            
            Text(badge.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isEarned ? appState.theme.textPrimary : appState.theme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
        .padding(16)
        .background(isEarned ? appState.theme.cardBackground : appState.theme.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEarned ? appState.accentColor.swiftUIColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: Badge
    let isEarned: Bool
    @EnvironmentObject var appState: AppState
    
    @State private var animationScale: CGFloat = 0.3
    @State private var animationRotation: Double = 0
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // 3D Animated Badge
                    VStack(spacing: 24) {
                        Text(badge.icon)
                            .font(.system(size: 120))
                            .scaleEffect(animationScale)
                            .rotation3DEffect(
                                .degrees(animationRotation),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .opacity(animationOpacity)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animationScale)
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animationRotation)
                            .animation(.easeInOut(duration: 0.6), value: animationOpacity)
                        
                        VStack(spacing: 16) {
                            Text(badge.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(appState.theme.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(badgeDescription)
                                .font(.system(size: 16))
                                .foregroundColor(appState.theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            if isEarned {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Achievement Unlocked!")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.green.opacity(0.2))
                                .cornerRadius(20)
                            } else {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(appState.theme.textMuted)
                                    Text("Not yet achieved")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(appState.theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(appState.theme.textMuted.opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Wait for sheet to fully present, then start animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Scale and opacity animation with dramatic effect
                withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                    animationScale = 1.0
                    animationOpacity = 1.0
                }
                
                // Start rotation shortly after scale animation begins
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        animationRotation = 360
                    }
                }
            }
        }
    }
    
    private var badgeDescription: String {
        switch badge.requirement {
        case .benchPress(let weight):
            return "Achieve a bench press personal record of \(weight) lbs or more. This milestone demonstrates your upper body strength and dedication to training."
        case .squat(let weight):
            return "Reach a squat personal record of \(weight) lbs or more. This achievement shows your lower body power and commitment to leg training."
        case .deadlift(let weight):
            return "Hit a deadlift personal record of \(weight) lbs or more. This milestone proves your full-body strength and lifting prowess."
        case .total(let weight):
            return "Achieve a combined total of \(weight) lbs across your bench press, squat, and deadlift. This demonstrates your overall strength across all major lifts."
        }
    }
}

// MARK: - Add Workout Sheet

struct AddWorkoutSheet: View {
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @EnvironmentObject var appState: AppState
    
    @State private var workoutName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    // Icon
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(appState.accentColor.swiftUIColor)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Add Custom Workout")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(appState.theme.textPrimary)
                        
                        Text("Enter the name of the exercise you want to track")
                            .font(.system(size: 16))
                            .foregroundColor(appState.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Text Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXERCISE NAME")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(appState.theme.textSecondary)
                        
                        TextField("e.g., Overhead Press", text: $workoutName)
                            .focused($isTextFieldFocused)
                            .font(.system(size: 16))
                            .foregroundColor(appState.theme.textPrimary)
                            .padding(16)
                            .background(appState.theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextFieldFocused ? appState.accentColor.swiftUIColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(appState.theme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave(workoutName)
                    }
                    .foregroundColor(appState.accentColor.swiftUIColor)
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#Preview {
    RecordsView()
        .environmentObject(AppState())
        .environmentObject(CalendarManager())
}
