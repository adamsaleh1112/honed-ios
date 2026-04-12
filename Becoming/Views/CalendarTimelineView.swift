import SwiftUI

struct CalendarTimelineView: View {
    @EnvironmentObject var videoManager: VideoManager
    @Binding var selectedDate: Date
    @State private var showingVideoPlayer = false
    @State private var selectedVideo: VideoEntry?
    @State private var currentMonthIndex = 0
    
    private let calendar = Calendar.current
    private let visibleMonthRange = -12...12 // Show 12 months back and forward
    
    var body: some View {
        VStack(spacing: 12) {
            // Day headers (fixed, not swiping)
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                }
            }
            
            // Horizontal paging months
            TabView(selection: $currentMonthIndex) {
                ForEach(Array(visibleMonthRange), id: \.self) { offset in
                    MonthGridView(
                        monthOffset: offset,
                        selectedDate: $selectedDate,
                        videoManager: videoManager,
                        onVideoTap: { video in
                            selectedVideo = video
                            showingVideoPlayer = true
                        }
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)
        }
        .onAppear {
            currentMonthIndex = 0
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
        .sheet(isPresented: $showingVideoPlayer) {
            if let video = selectedVideo {
                VideoPlayerView(videoURL: video.videoURL, entry: video)
            }
        }
    }
}

struct MonthGridView: View {
    let monthOffset: Int
    @Binding var selectedDate: Date
    let videoManager: VideoManager
    let onVideoTap: (VideoEntry) -> Void
    
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
            ForEach(calendarDays, id: \.self) { date in
                let video = videoManager.getVideoForDate(date)
                CalendarDayView(
                    date: date,
                    video: video,
                    isCurrentMonth: calendar.isDate(date, equalTo: monthDate, toGranularity: .month),
                    isToday: calendar.isDateInToday(date),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                ) {
                    selectedDate = date
                    if let video = video {
                        onVideoTap(video)
                    }
                }
            }
        }
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
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                } else {
                    // Day number (shown when no thumbnail)
                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 16, weight: hasVideo ? .bold : .medium, design: .rounded))
                        .foregroundColor(textColor)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
                }
                
                // Today indicator - blue dot centered at bottom (only when no thumbnail)
                if isToday && video?.thumbnailURL == nil {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color.blue)
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
                
                // Video indicator dot (only when no thumbnail)
                if hasVideo && video?.thumbnailURL == nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .offset(x: -4, y: -4)
                                .scaleEffect(isPressed ? 0.8 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
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
            return Color.blue.opacity(0.3)
        } else if isToday && video?.thumbnailURL == nil {
            return Color.white.opacity(0.2)
        } else if hasVideo && video?.thumbnailURL == nil {
            return Color.white.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return Color.gray.opacity(0.5)
        } else if isSelected {
            return Color.white
        } else if isToday {
            return Color.white
        } else if hasVideo {
            return Color.white
        } else {
            return Color.gray
        }
    }
}

#Preview {
    CalendarTimelineView(selectedDate: .constant(Date()))
        .environmentObject(VideoManager())
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
}
