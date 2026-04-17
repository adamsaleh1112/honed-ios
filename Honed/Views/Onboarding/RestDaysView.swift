import SwiftUI

struct RestDaysView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        ZStack {
            DarkMeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("REST DAYS")
                        .font(.system(size: 32, weight: .regular))
                        .fontWidth(.expanded)
                        .foregroundColor(appState.theme.textPrimary)
                    
                    Text("Select any days you can't work out")
                        .font(.system(size: 17))
                        .foregroundColor(appState.theme.textMuted)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Day selector
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(0..<7, id: \.self) { index in
                            DayToggleButton(
                                day: daysOfWeek[index],
                                index: index,
                                isSelected: authState.restDays.contains(index),
                                action: { toggleDay(index) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Calendar preview
                    MiniCalendarPreview(routine: authState.routine, restDays: authState.restDays)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Continue button
                VStack(spacing: 12) {
                    Button(action: completeOnboarding) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(appState.accentColor.swiftUIColor)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: skipStep) {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(appState.theme.textMuted)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func toggleDay(_ index: Int) {
        HapticManager.shared.light()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if authState.restDays.contains(index) {
                authState.restDays.removeAll { $0 == index }
            } else {
                authState.restDays.append(index)
                authState.restDays.sort()
            }
        }
    }
    
    private func skipStep() {
        HapticManager.shared.soft()
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        HapticManager.shared.heavy()
        
        // Save to app state
        appState.isOnboarded = true
        appState.saveUserDefaults()
        
        // Complete auth onboarding
        authState.completeOnboarding()
    }
}

struct DayToggleButton: View {
    let day: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.uppercased())
                    .font(.system(size: 20, weight: .medium))
                    .fontWidth(.compressed)
                
                Circle()
                    .fill(isSelected ? appState.accentColor.swiftUIColor : appState.theme.cardBackground)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : appState.theme.textMuted.opacity(0.3), lineWidth: 1)
                    )
            }
            .foregroundColor(isSelected ? appState.theme.textPrimary : appState.theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? appState.accentColor.swiftUIColor.opacity(0.15) : appState.theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? appState.accentColor.swiftUIColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniCalendarPreview: View {
    let routine: UserRoutine
    let restDays: [Int]
    @EnvironmentObject var appState: AppState
    
    private let calendar = Calendar.current
    private let daysToShow = 14
    
    var body: some View {
        let startDate = Date()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(0..<daysToShow, id: \.self) { offset in
                if let date = calendar.date(byAdding: .day, value: offset, to: startDate) {
                    let weekday = calendar.component(.weekday, from: date) - 1
                    let isRestDay = restDays.contains(weekday)
                    let workoutDay = routine.workoutForDate(date, startingFrom: startDate)
                    
                    MiniDayCell(
                        date: date,
                        isRestDay: isRestDay,
                        workoutDay: workoutDay
                    )
                }
            }
        }
        .padding(12)
        .background(appState.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MiniDayCell: View {
    let date: Date
    let isRestDay: Bool
    let workoutDay: WorkoutDayType?
    @EnvironmentObject var appState: AppState
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .frame(height: 36)
            
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 16, weight: .medium))
                    .fontWidth(.compressed)
                    .foregroundColor(textColor)
                
                if let day = workoutDay {
                    Circle()
                        .fill(day.swiftUIColor)
                        .frame(width: 4, height: 4)
                } else if isRestDay {
                    Circle()
                        .fill(appState.theme.textMuted.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isRestDay {
            return appState.theme.textMuted.opacity(0.1)
        } else if workoutDay != nil {
            return (workoutDay?.swiftUIColor ?? .clear).opacity(0.15)
        }
        return Color.clear
    }
    
    private var textColor: Color {
        if isRestDay {
            return appState.theme.textMuted.opacity(0.5)
        }
        return appState.theme.textPrimary
    }
}

#Preview {
    RestDaysView()
        .environmentObject(AuthState())
        .environmentObject(AppState())
}
