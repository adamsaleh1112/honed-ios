import SwiftUI

struct RoutineBuilderView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @State private var showingDayPicker = false
    @State private var draggedItem: WorkoutDayType?
    
    var body: some View {
        ZStack {
            DarkMeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("BUILD YOUR ROUTINE")
                        .font(.system(size: 32, weight: .regular))
                        .fontWidth(.expanded)
                        .foregroundColor(appState.theme.textPrimary)
                    
                    Text("Add days to create your workout cycle")
                        .font(.system(size: 17))
                        .foregroundColor(appState.theme.textMuted)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // Routine display
                if authState.routine.days.isEmpty {
                    // Empty state
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 48))
                            .foregroundColor(appState.theme.textMuted.opacity(0.5))
                        
                        Text("Add your first workout day")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(appState.theme.textPrimary)
                        
                        Text("Build a custom routine that fits your schedule")
                            .font(.system(size: 15))
                            .foregroundColor(appState.theme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                } else {
                    // List of days
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(authState.routine.days.enumerated()), id: \.element.id) { index, day in
                                RoutineDayCard(
                                    day: day,
                                    index: index,
                                    onDelete: { deleteDay(at: index) },
                                    onMove: { direction in moveDay(from: index, direction: direction) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    Button(action: { showingDayPicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Day")
                        }
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
                    
                    Button(action: continueToRestDays) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(authState.routine.days.isEmpty ? appState.theme.textMuted : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(authState.routine.days.isEmpty ? appState.theme.cardBackground : appState.accentColor.swiftUIColor)
                            )
                    }
                    .disabled(authState.routine.days.isEmpty)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingDayPicker) {
            DayPickerSheet { dayType in
                authState.routine.days.append(dayType)
                showingDayPicker = false
            }
            .environmentObject(appState)
        }
    }
    
    private func deleteDay(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            authState.routine.days.remove(at: index)
        }
    }
    
    private func moveDay(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < authState.routine.days.count else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            authState.routine.days.swapAt(index, newIndex)
        }
    }
    
    private func continueToRestDays() {
        HapticManager.shared.heavy()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            authState.nextStep()
        }
    }
}

struct RoutineDayCard: View {
    let day: WorkoutDayType
    let index: Int
    let onDelete: () -> Void
    let onMove: (Int) -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Index number
            Text("\(index + 1)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(appState.theme.textMuted)
                .frame(width: 32)
            
            // Icon
            Image(systemName: day.icon)
                .font(.system(size: 20))
                .foregroundColor(day.swiftUIColor)
                .frame(width: 40, height: 40)
                .background(day.swiftUIColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Name
            Text(day.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(appState.theme.textPrimary)
            
            Spacer()
            
            // Move buttons
            VStack(spacing: 4) {
                Button(action: { onMove(-1) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appState.theme.textMuted)
                }
                .disabled(index == 0)
                
                Button(action: { onMove(1) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appState.theme.textMuted)
                }
                .disabled(index == 0)
            }
            .frame(width: 32)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(appState.theme.textMuted.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(appState.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let onSelect: (WorkoutDayType) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(WorkoutDayType.allTypes) { dayType in
                        Button(action: {
                            onSelect(dayType)
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: dayType.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(dayType.swiftUIColor)
                                
                                Text(dayType.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(appState.theme.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(dayType.swiftUIColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(dayType.swiftUIColor.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .navigationTitle("Select Day Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RoutineBuilderView()
        .environmentObject(AuthState())
        .environmentObject(AppState())
}
