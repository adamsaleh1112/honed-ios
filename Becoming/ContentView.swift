import SwiftUI

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
    @State private var showingRecordingView = false
    @State private var showingSettingsView = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    Button(action: {
                        // Profile action - could show streak info
                    }) {
                        VStack(spacing: 4) {
                            Text("\(streakManager.currentStreak)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text("days")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettingsView = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Calendar Timeline
                CalendarTimelineView()
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Floating Record Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingRecordingView = true
                    }) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingRecordingView) {
            RecordingView()
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
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
