import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingView()
            } else {
                MainView()
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    @State private var selectedDate = Date()
    
    var body: some View {
        TabView {
            // Home Tab
            HomeContentView(selectedDate: $selectedDate)
                .tabItem {
                    Image(systemName: "calendar")
                }
            
            // Record Tab
            RecordingView()
                .tabItem {
                    Image(systemName: "video.fill")
                }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                }
        }
        .tint(.white)
    }
}

struct HomeContentView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Date Header
                DateHeaderView(selectedDate: $selectedDate)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                // Calendar Timeline - full width for seamless swiping
                CalendarTimelineView(selectedDate: $selectedDate)
                    .padding(.top, 30)
                
                Spacer()
            }
        }
        .onAppear {
            // Re-prepare haptics when returning to Home tab
            HapticManager.shared.prepareLight()
            HapticManager.shared.prepareSoft()
        }
    }
}

struct DateHeaderView: View {
    @Binding var selectedDate: Date
    @State private var isVisible = false
    
    private var monthNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter.string(from: selectedDate)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: selectedDate)
    }
    
    private var yearNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Month (grayed out)
            Text(monthNumber)
                .font(.system(size: 64, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(.white.opacity(0.4))
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                .id("month-\(monthNumber)")
            
            // Day (white)
            Text(dayNumber)
                .font(.system(size: 64, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .transition(.asymmetric(insertion: .scale(scale: 1.2).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity)))
                .id("day-\(dayNumber)")
            
            // Year (grayed out)
            Text(yearNumber)
                .font(.system(size: 64, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(.white.opacity(0.4))
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .id("year-\(yearNumber)")
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedDate)
    }
}

struct FloatingRecordButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var isVisible = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            // Trigger action with subtle animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                action()
            }
        }) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .opacity(isPressed ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 0.6), value: isPressed)
                
                // Main button
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isPressed)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.3), value: isVisible)
                
                // Icon
                Image(systemName: "video.fill")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
        .environmentObject(VideoManager())
        .environmentObject(StreakManager())
}

#Preview("Date Header") {
    DateHeaderView(selectedDate: .constant(Date()))
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
}