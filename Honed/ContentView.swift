import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        ZStack {
            appState.theme.background.ignoresSafeArea()
            
            if appState.isOnboarded {
                MainView()
                    .transition(.blurReplace)
            } else {
                OnboardingView()
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
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Calendar
            HomeContentView(selectedDate: $selectedDate)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Home")
                }
                .tag(0)
            
            // Records Tab
            RecordsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Records")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(appState.theme.textPrimary)
    }
}

struct HomeContentView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var appState: AppState
    
    // Staggered animation states
    @State private var headerOpacity = 0.0
    @State private var headerOffset: CGFloat = -15
    @State private var lineOpacity = 0.0
    @State private var lineOffset: CGFloat = -15
    @State private var calendarOpacity = 0.0
    @State private var calendarOffset: CGFloat = -15
    
    // Bottom sheet states
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    private let expandedHeight: CGFloat = 840
    private let peekOffset: CGFloat = 600
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        GeometryReader { geometry in
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
                .opacity(lineOpacity)
                .offset(y: lineOffset)
                
                // Calendar Timeline
                CalendarTimelineView(selectedDate: $selectedDate)
                    .padding(.top, 16)
                    .opacity(calendarOpacity)
                    .offset(y: calendarOffset)
                
                Spacer()
            }
            
            // Draggable bottom sheet - always 840px, slides up/down
            VStack(spacing: 0) {
                Spacer()
                DayDetailsSheet(
                    selectedDate: $selectedDate,
                    isExpanded: isExpanded
                )
                .frame(height: expandedHeight)
                .offset(y: (isExpanded ? 0 : peekOffset) + dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            isDragging = true
                            let translation = value.translation.height
                            let maxOverDrag: CGFloat = 24
                            let dampingFactor: CGFloat = 0.3
                            
                            if isExpanded {
                                // From expanded (offset 0), dragging down goes toward peek
                                // Free movement until reaching peekOffset, then damp beyond
                                if translation >= 0 && translation <= peekOffset {
                                    // Within range: follow finger 1:1
                                    dragOffset = translation
                                } else if translation > peekOffset {
                                    // Beyond peek: damp the over-drag
                                    let overDrag = translation - peekOffset
                                    dragOffset = peekOffset + maxOverDrag * (1 - exp(-dampingFactor * overDrag / maxOverDrag))
                                } else {
                                    // Trying to drag up from expanded (beyond range): damp
                                    dragOffset = -maxOverDrag * (1 - exp(dampingFactor * translation / maxOverDrag))
                                }
                            } else {
                                // From peek (offset peekOffset), dragging up goes toward expanded
                                // Free movement until reaching 0, then damp beyond
                                if translation <= 0 && translation >= -peekOffset {
                                    // Within range: follow finger 1:1
                                    dragOffset = translation
                                } else if translation < -peekOffset {
                                    // Beyond expanded: damp the over-drag
                                    let overDrag = abs(translation) - peekOffset
                                    dragOffset = -peekOffset - maxOverDrag * (1 - exp(-dampingFactor * overDrag / maxOverDrag))
                                } else {
                                    // Trying to drag down from peek (beyond range): damp
                                    dragOffset = maxOverDrag * (1 - exp(-dampingFactor * translation / maxOverDrag))
                                }
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let dragAmount = value.translation.height
                            let velocity = value.predictedEndLocation.y - value.location.y
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if dragAmount > 100 || velocity > 300 {
                                    isExpanded = false
                                } else if dragAmount < -100 || velocity < -300 {
                                    isExpanded = true
                                }
                                // Reset drag offset - sheet will animate to new position
                                dragOffset = 0
                            }
                        }
                )
                .onChange(of: isExpanded) { _ in
                    feedbackGenerator.impactOccurred()
                }
                .onAppear {
                    feedbackGenerator.prepare()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
            .onAppear {
                // Reset states first for re-animation
                headerOpacity = 0
                headerOffset = -15
                lineOpacity = 0
                lineOffset = -15
                calendarOpacity = 0
                calendarOffset = -15
                
                // Staggered reveal from top to bottom
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    headerOpacity = 1
                    headerOffset = 0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                    lineOpacity = 1
                    lineOffset = 0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                    calendarOpacity = 1
                    calendarOffset = 0
                }
            }
        }
    }
}

struct DateHeaderView: View {
    @Binding var selectedDate: Date
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
                .font(.system(size: 48, weight: .regular))
                .fontWidth(.expanded)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("month-\(monthNumber)")
            
            // Day (primary text)
            Text(dayNumber)
                .font(.system(size: 48, weight: .regular))
                .fontWidth(.expanded)
                .foregroundColor(appState.theme.textPrimary)
                .transition(.asymmetric(insertion: .scale(scale: 1.2).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity)))
                .id("day-\(dayNumber)")
            
            // Year (grayed out)
            Text(yearNumber)
                .font(.system(size: 48, weight: .regular))
                .fontWidth(.expanded)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("year-\(yearNumber)")
            
            // Accent color bullet for today
            if isToday {
                Text("•")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.leading, 4)
                    .transition(.asymmetric(insertion: .scale(scale: 1.2).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity)))
            }
            
            Spacer()
            
            // Day of week abbreviation (top right)
            Text(dayAbbreviation.uppercased())
                .font(.system(size: 48, weight: .regular))
                .fontWidth(.compressed)
                .foregroundColor(appState.theme.textMuted)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)), removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5))))
                .id("dayAbbr-\(dayAbbreviation)")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedDate)
    }
}

struct DayDetailsSheet: View {
    @Binding var selectedDate: Date
    let isExpanded: Bool
    @EnvironmentObject var appState: AppState
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(appState.theme.textMuted.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            // Date header in sheet
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.system(size: 20, weight: .semibold))
                        .fontWidth(.expanded)
                        .foregroundColor(appState.theme.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Content area
            VStack {
                Spacer()
                
                Text("Workout details coming soon")
                    .font(.system(size: 16))
                    .foregroundColor(appState.theme.textMuted)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.5))
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 52, style: .continuous))
        .overlay(
            // Gradient stroke that fades from gray at top to black halfway down
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 52, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.55)
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: -6)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(CalendarManager())
        .preferredColorScheme(.dark)
}
