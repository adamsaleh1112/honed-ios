import SwiftUI
import AVKit

struct TimelineView: View {
    @EnvironmentObject var videoManager: VideoManager
    @State private var selectedVideo: VideoEntry?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if videoManager.videoEntries.isEmpty {
                    EmptyTimelineView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(videoManager.videoEntries) { entry in
                                VideoEntryCard(entry: entry) {
                                    selectedVideo = entry
                                    showingVideoPlayer = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let video = selectedVideo {
                VideoPlayerView(videoURL: video.videoURL, entry: video)
            }
        }
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Videos Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Start recording your daily logs to see them here")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct VideoEntryCard: View {
    let entry: VideoEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Thumbnail or placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 60)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.formattedDate)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(formatDuration(entry.duration))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if entry.isFromToday {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    } else if entry.isFromYesterday {
                        Text("Yesterday")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    let entry: VideoEntry
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle(entry.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
    }
}

#Preview {
    TimelineView()
        .environmentObject(VideoManager())
}
