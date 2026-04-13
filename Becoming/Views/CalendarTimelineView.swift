import SwiftUI
import AVKit

struct CalendarTimelineView: View {
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var appState: AppState
    @Binding var selectedDate: Date
    @State private var currentMonthIndex = 0
    var onVideoSelected: ((VideoEntry) -> Void)? = nil
    
    private let calendar = Calendar.current
    private let visibleMonthRange = -12...12 // Show 12 months back and forward
    
    // Cache day headers for performance
    private let dayHeaders = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers (fixed, not swiping)
            HStack {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(appState.isLowercaseMode ? day.lowercased() : day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 14)
                }
            }
            .padding(.horizontal, 20)

            // Horizontal paging months
            TabView(selection: $currentMonthIndex) {
                ForEach(Array(visibleMonthRange), id: \.self) { offset in
                    MonthGridView(
                        monthOffset: offset,
                        selectedDate: $selectedDate,
                        videoManager: videoManager,
                        onVideoTap: { video in
                            HapticManager.shared.medium()
                            onVideoSelected?(video)
                        }
                    )
                    .environmentObject(appState)
                    .tag(offset)
                }
                .onChange(of: currentMonthIndex) { _ in
                    HapticManager.shared.soft()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 420)
        }
        .onAppear {
            currentMonthIndex = 0
            // Preemptively prepare haptic generators
            HapticManager.shared.prepareLight()
            HapticManager.shared.prepareSoft()
        }
        .onChange(of: currentMonthIndex) { newIndex in
            // Update selected date to the first day of the new month
            if let newDate = calendar.date(byAdding: .month, value: newIndex, to: Date()) {
                // Keep the day if possible, otherwise clamp to month end
                let day = calendar.component(.day, from: selectedDate)
                var components = calendar.dateComponents([.year, .month], from: newDate)
                components.day = min(day, calendar.range(of: .day, in: .month, for: newDate)?.count ?? day)
                if let finalDate = calendar.date(from: components) {
                    selectedDate = finalDate
                }
            }
        }
        .padding(.top, 16)
    }
}

struct MonthGridView: View {
    let monthOffset: Int
    @Binding var selectedDate: Date
    let videoManager: VideoManager
    let onVideoTap: (VideoEntry) -> Void
    
    @EnvironmentObject var appState: AppState
    private let calendar = Calendar.current
    
    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(monthDate, equalTo: Date(), toGranularity: .month)
    }
    
    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return []
        }
        
        let monthFirstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysToSubtract = monthFirstWeekday - 1
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthInterval.start) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = startDate
        
        // Generate 42 days (6 weeks) to fill the calendar grid
        for _ in 0..<42 {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
            ForEach(calendarDays, id: \.self) { date in
                let video = videoManager.getVideoForDate(date)
                CalendarDayView(
                    date: date,
                    video: video,
                    isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                    isToday: calendar.isDateInToday(date),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                ) {
                    HapticManager.shared.light()
                    selectedDate = date
                    if let video = video {
                        onVideoTap(video)
                    }
                }
                .environmentObject(appState)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func hasVideoForDate(_ date: Date) -> Bool {
        return videoManager.getVideoForDate(date) != nil
    }
}

struct CalendarDayView: View {
    let date: Date
    let video: VideoEntry?
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false
    
    private var hasVideo: Bool { video != nil }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(height: 52)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
                
                // Thumbnail image if video exists
                if let thumbnailURL = video?.thumbnailURL,
                   let uiImage = UIImage(contentsOfFile: thumbnailURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isCurrentMonth ? 1.0 : 0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? appState.accentColor.swiftUIColor : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            // Small day number in top left
                            HStack {
                                VStack {
                                    Text(dayFormatter.string(from: date))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                                        .padding(.leading, 6)
                                        .padding(.top, 4)
                                    Spacer()
                                }
                                Spacer()
                            }
                        )
                } else {
                    // Day number (shown when no thumbnail)
                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 22, weight: hasVideo ? .bold : .medium, design: .rounded)) // CAL DAYS HERE
                        .foregroundColor(textColor)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
                }
                
                // Today indicator - blue dot centered at bottom (only when no thumbnail)
                if isToday && video?.thumbnailURL == nil {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(appState.accentColor.swiftUIColor)
                            .frame(width: 6, height: 6)
                            .padding(.bottom, 6)
                    }
                }
                
                // Play icon overlay for videos with thumbnails
                if video?.thumbnailURL != nil {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                // Rating indicator dot (or white dot if no rating)
                if hasVideo && video?.thumbnailURL == nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(video?.ratingColor ?? Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .offset(x: -4, y: -4)
                                .scaleEffect(isPressed ? 0.8 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
                        }
                    }
                }
                
                // Rating indicator dot on thumbnails (bottom right)
                if video?.thumbnailURL != nil, let rating = video?.rating {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(video?.ratingColor ?? Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .offset(x: -4, y: -4)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var backgroundColor: Color {
        if isSelected && video?.thumbnailURL == nil {
            return appState.accentColor.swiftUIColor.opacity(0.3)
        } else if isToday && video?.thumbnailURL == nil {
            return appState.theme.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
        } else if hasVideo && video?.thumbnailURL == nil {
            return appState.theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return Color.gray.opacity(0.5)
        } else if isSelected {
            return appState.theme.textPrimary
        } else if isToday {
            return appState.theme.textPrimary
        } else if hasVideo {
            return appState.theme.textPrimary
        } else {
            return appState.theme.textSecondary
        }
    }
}

#Preview {
    CalendarTimelineView(selectedDate: .constant(Date()))
        .environmentObject(VideoManager())
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
}
