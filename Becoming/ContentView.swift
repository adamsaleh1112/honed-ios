import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        ZStack {
            // Background color to fill any gaps during transition
            appState.theme.background
                .ignoresSafeArea()

            if !appState.isOnboarded {
                OnboardingView()
                    .transition(.blurReplace)
            } else {
                MainView()
                    .transition(.blurReplace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: appState.isOnboarded)
    }
}

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    @State private var selectedDate = Date()
    @State private var selectedTab = 0  // Home tab by default
    
    // Computed properties for better performance
    private var hasRecordedToday: Bool {
        videoManager.hasRecordedToday()
    }
    
    private var currentStreak: Int {
        streakManager.currentStreak
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeContentView(selectedDate: $selectedDate, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "calendar")
                }
                .tag(0)
                .onAppear {
                    HapticManager.shared.prepareMedium()
                }
            
            // Record Tab
            RecordingView(onVideoSaved: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "plus.viewfinder")
                }
                .tag(1)
                .onAppear {
                    HapticManager.shared.prepareLight()
                    HapticManager.shared.prepareMedium()
                    HapticManager.shared.prepareRigid()
                }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                }
                .tag(2)
                .onAppear {
                    HapticManager.shared.prepareLight()
                }
        }
        .tint(appState.theme.textPrimary)
    }
}

struct HomeContentView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var appState: AppState
    @State private var showingVideoPreview = false
    @State private var showingVideoPlayer = false
    @State private var selectedVideo: VideoEntry?
    @State private var showingStreakPopup = false

    // Staggered animation states
    @State private var headerOpacity = 0.0
    @State private var headerOffset: CGFloat = -15
    @State private var calendarOpacity = 0.0
    @State private var calendarOffset: CGFloat = -15
    @State private var bottomOpacity = 0.0
    @State private var bottomOffset: CGFloat = -15

    var body: some View {
        ZStack {
            appState.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Date Header
                DateHeaderView(selectedDate: $selectedDate)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(headerOpacity)
                    .offset(y: headerOffset)

                // Dotted line separator
                HStack(spacing: 5.5) {
                    ForEach(0..<42) { _ in
                        Circle()
                            .fill(appState.theme.dotColor)
                            .frame(width: 3, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Calendar Timeline - full width for seamless swiping
                CalendarTimelineView(
                    selectedDate: $selectedDate,
                    onVideoSelected: { video in
                        HapticManager.shared.medium()
                        selectedVideo = video
                        showingVideoPreview = true
                    }
                )
                .padding(.top, 16)
                .opacity(calendarOpacity)
                .offset(y: calendarOffset)
                
                Spacer()
                
                // Streak and Entry Status
                HStack(spacing: 12) {
                    StreakCounterView()
                        .onTapGesture {
                            HapticManager.shared.light()
                            showingStreakPopup = true
                        }
                    EntryStatusView(selectedTab: $selectedTab)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(bottomOpacity)
                .offset(y: bottomOffset)
            }
            
            // Video Preview Popup - over entire screen
            ZStack {
                // Dimmed background
                if showingVideoPreview {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            HapticManager.shared.light()
                            showingVideoPreview = false
                        }
                        .transition(.opacity)
                }
                
                // Popup content
                if showingVideoPreview, let video = selectedVideo {
                    VideoPreviewPopup(
                        video: video,
                        onPlay: {
                            showingVideoPreview = false
                            showingVideoPlayer = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: showingVideoPreview)
            
            // Streak Popup Overlay
            ZStack {
                // Dimmed background
                if showingStreakPopup {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingStreakPopup = false
                        }
                        .transition(.opacity)
                }
                
                // Popup content
                if showingStreakPopup {
                    StreakPopup(onClose: {
                        showingStreakPopup = false
                    })
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: showingStreakPopup)
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let video = selectedVideo {
                VideoPlayerView(videoURL: video.videoURL, entry: video)
            }
        }
        .onAppear {
            // Re-prepare haptics when returning to Home tab
            HapticManager.shared.prepareLight()
            HapticManager.shared.prepareSoft()

            // Staggered fade-in animation
            headerOpacity = 0
            headerOffset = -15
            calendarOpacity = 0
            calendarOffset = -15
            bottomOpacity = 0
            bottomOffset = -15

            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                headerOpacity = 1
                headerOffset = 0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                calendarOpacity = 1
                calendarOffset = 0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                bottomOpacity = 1
                bottomOffset = 0
            }
        }
    }
}

struct DateHeaderView: View {
    @Binding var selectedDate: Date
    @State private var isVisible = false
    @EnvironmentObject var appState: AppState

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var accentColor: Color {
        return appState.accentColor.swiftUIColor
    }

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

    private var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Month (grayed out)
            Text(monthNumber)
                .font(.system(size: 58, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("month-\(monthNumber)")
            
            // Day (primary text)
            Text(dayNumber)
                .font(.system(size: 58, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(appState.theme.textPrimary)
                .transition(.asymmetric(insertion: .scale(scale: 1.2).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity)))
                .id("day-\(dayNumber)")
            
            // Year (grayed out)
            Text(yearNumber)
                .font(.system(size: 58, weight: .bold))
                //.fontWidth(.expanded)
                .fontDesign(.rounded)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("year-\(yearNumber)")
            
            // Accent color bullet for today
            if isToday {
                Text("•")
                    .font(.system(size: 58, weight: .bold))
                    //.fontWidth(.expanded)
                    .fontDesign(.rounded)
                    .foregroundColor(accentColor)
                    .padding(.leading, 4)
                    .transition(.asymmetric(insertion: .scale(scale: 1.2).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity)))
            }
            
            Spacer()
            
            // Day of week abbreviation (top right)
            Text(appState.isLowercaseMode ? dayAbbreviation.lowercased() : dayAbbreviation)
                .font(.system(size: 26, weight: .medium))
                .fontDesign(.rounded)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("dayAbbr-\(dayAbbreviation)")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedDate)
    }
}

struct StreakCounterView: View {
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var appState: AppState

    private var streakColor: Color {
        let count = streakManager.currentStreak
        switch count {
        case 0: return appState.theme.textPrimary
        case 1...10: return .orange
        case 11...20: return .red
        case 21...30: return .purple
        case 31...60: return .blue
        case 61...120: return .cyan
        default: return .yellow // Gold
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Fire icon
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(streakColor)

            // Streak count
            Text("\(streakManager.currentStreak)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 26)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 48)
                .fill(appState.theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 48)
                .stroke(appState.theme.stroke, lineWidth: 1)
        )
    }
}

struct EntryStatusView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var appState: AppState

    private var hasEntryToday: Bool {
        videoManager.getVideoForDate(Date()) != nil
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            selectedTab = 1 // Switch to recording tab
        }) {
            HStack(spacing: 8) {
                if hasEntryToday {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(appState.theme.textPrimary)

                    Text(appState.isLowercaseMode ? "Entry recorded".lowercased() : "Entry recorded")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(appState.theme.textPrimary)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(appState.theme.textSecondary)

                    Text(appState.isLowercaseMode ? "No entry today".lowercased() : "No entry today")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(appState.theme.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 26)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 48)
                .fill(appState.theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 48)
                .stroke(appState.theme.stroke, lineWidth: 1)
        )
    }
}

struct VideoPreviewPopup: View {
    let video: VideoEntry
    let onPlay: () -> Void
    @EnvironmentObject var appState: AppState
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d yyyy"
        return formatter.string(from: video.date)
    }
    
    private var formattedDuration: String {
        let minutes = Int(video.duration) / 60
        let seconds = Int(video.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        // Thumbnail as full background popup
        if let thumbnailURL = video.thumbnailURL,
           let uiImage = UIImage(contentsOfFile: thumbnailURL.path) {
            Button(action: {
                HapticManager.shared.medium()
                onPlay()
            }) {
                ZStack {
                    // Full thumbnail background
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 260, height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Top gradient overlay
                    VStack(spacing: 0) {
                        // Gradient from top
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(0.7), location: 0.0),
                                .init(color: .black.opacity(0.4), location: 0.4),
                                .init(color: .clear, location: 0.7)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        
                        Spacer()
                    }
                    .frame(width: 260, height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Top info overlay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.isLowercaseMode ? formattedDate.lowercased() : formattedDate)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(formattedDuration)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            // Rating badge
                            if let rating = video.rating {
                                HStack(spacing: 3) {
                                    // Circle()
                                    //     .fill(video.ratingColor)
                                    //     .frame(width: 12, height: 12)
                                    
                                    Text("\(rating)")
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundColor(video.ratingColor)

                                    Text("/ 10")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.3))
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .frame(width: 260, height: 420)
                    
                    // Center play button
                    Image(systemName: "play.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 6)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
        } else {
            EmptyView()
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    let entry: VideoEntry
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            player.play()
                        }
                } else {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text(appState.isLowercaseMode ? "Loading video...".lowercased() : "Loading video...")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(appState.isLowercaseMode ? "Done".lowercased() : "Done") {
                        player?.pause()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text(formattedDate(entry.date))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Initialize player with optimized loading on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVURLAsset(url: videoURL, options: [
                    AVURLAssetPreferPreciseDurationAndTimingKey: false,
                    AVURLAssetReferenceRestrictionsKey: AVAssetReferenceRestrictions.forbidAll.rawValue
                ])
                
                // Preload essential properties
                let keys = ["playable", "tracks"]
                asset.loadValuesAsynchronously(forKeys: keys) {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: "playable", error: &error)
                    
                    guard status == .loaded else {
                        print("Error loading video: \(error?.localizedDescription ?? "unknown")")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let playerItem = AVPlayerItem(asset: asset)
                        
                        // Optimize buffer for faster start
                        playerItem.preferredForwardBufferDuration = 2.0 // Start playing with 2 seconds buffered
                        
                        let newPlayer = AVPlayer(playerItem: playerItem)
                        newPlayer.automaticallyWaitsToMinimizeStalling = false // Start immediately
                        
                        self.player = newPlayer
                        newPlayer.play()
                        self.isLoading = false
                    }
                }
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StreakPopup: View {
    let onClose: () -> Void
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var appState: AppState
    @State private var glintOffset: CGFloat = -400
    
    private var streakColor: Color {
        let count = streakManager.currentStreak
        switch count {
        case 0: return .white
        case 1...10: return .orange
        case 11...20: return .red
        case 21...30: return .purple
        case 31...60: return .blue
        case 61...120: return .cyan
        default: return .yellow // Gold
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(appState.isLowercaseMode ? "Your current streak is".lowercased() : "Your current streak is")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Fire icon to the left of the number
                Image(systemName: "flame.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(streakColor)
                
                Text("\(streakManager.currentStreak)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)
            }
        }
        .padding(28)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                
                // Glint effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: glintOffset)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                        .delay(0.5),
                        value: glintOffset
                    )
                
                // Border overlay
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .onAppear {
            // Start glint animation
            glintOffset = 400
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
        .environmentObject(VideoManager())
        .environmentObject(StreakManager())
        .preferredColorScheme(.dark)
}

#Preview("Date Header") {
    DateHeaderView(selectedDate: .constant(Date()))
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
}
