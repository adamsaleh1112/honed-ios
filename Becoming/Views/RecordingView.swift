import SwiftUI
import AVFoundation
import UIKit

struct RecordingView: View {
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    
    @StateObject private var cameraManager = CameraManager()
    @State private var recordedVideoURL: URL?
    @State private var showSaveButton = false
    @State private var isFrontCamera = true
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var dailyPrompt = ""
    @State private var hasStartedRecording = false
    @State private var showRatingPopup = false
    @State private var selectedRating: Int? = nil
    @State private var recordingSegments: [URL] = []
    @State private var isProcessingCameraSwitch = false
    
    var onVideoSaved: (() -> Void)? = nil
    
    @EnvironmentObject var appState: AppState
    
    private let dailyPrompts = [
        "How are you feeling today?",
        "What's on your mind?",
        "Talk about your day",
        "What happened today?",
        "What's your story today?",
        "Just say what comes to mind",
        "Say whatever's on your mind",
        "Share your thoughts"
    ]
    
    private let maxRecordingDuration: TimeInterval = 600 // 10 minutes
    
    var body: some View {
        ZStack {
            // Full screen camera preview at back
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06)
                CameraPreviewView(cameraManager: cameraManager)
                    .blur(radius: videoManager.hasRecordedToday() && !videoManager.isRecording && !showSaveButton ? 20 : 0)
                    .opacity(videoManager.hasRecordedToday() && !videoManager.isRecording && !showSaveButton ? 0.5 : 1)
                    .offset(y: -20)
            }
            .ignoresSafeArea()
            .onTapGesture(count: 2) {
                if !videoManager.hasRecordedToday() {
                    // Delay slightly to ensure haptic works with camera
                    DispatchQueue.main.async {
                        HapticManager.shared.medium()
                    }
                    flipCamera()
                }
            }
            
            // UI Overlay
            VStack {
                // Header with duration counter
                HStack {
                    // Button("Cancel") {
                    //     let impact = UIImpactFeedbackGenerator(style: .light)
                    //     impact.impactOccurred()
                    //     dismiss()
                    // }
                    // .foregroundColor(.white)
                    // .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    // Duration counter with subtle animation
                    if videoManager.isRecording || showSaveButton {
                        Text("\(formatTime(videoManager.recordingDuration)) / \(formatTime(maxRecordingDuration))")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.easeInOut(duration: 0.15), value: videoManager.recordingDuration)
                            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    }
                    
                    Spacer()
                    
                    // Camera flip button
                    // if !videoManager.isRecording && !showSaveButton {
                    //     Button(action: {
                    //         let impact = UIImpactFeedbackGenerator(style: .light)
                    //         impact.impactOccurred()
                    //         flipCamera()
                    //     }) {
                    //         Image(systemName: "camera.rotate.fill")
                    //             .font(.system(size: 22))
                    //             .foregroundColor(.white)
                    //             .frame(width: 44, height: 44)
                    //             .background(.ultraThinMaterial)
                    //             .clipShape(Circle())
                    //     }
                    // } else {
                    //     // Spacer for balance when button hidden
                    //     Color.clear.frame(width: 44, height: 44)
                    // }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Daily prompt (only before any recording starts in this session)
                if !videoManager.hasRecordedToday() && !hasStartedRecording && !videoManager.isRecording {
                    Text(appState.isLowercaseMode ? dailyPrompt.lowercased() : dailyPrompt)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        .padding(.top, 8)
                        .offset(y: -16)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeInOut(duration: 0.4)),
                            removal: .opacity.animation(.easeInOut(duration: 0.3))
                        ))
                }
                
                Spacer()
                
                // Recording Controls
                VStack(spacing: 20) {
                    // Recording Controls with animated blur
                    ZStack {
                        // Save/Confirm State
                        if showSaveButton, let url = recordedVideoURL {
                            HStack {
                                // Simple retry icon button
                                Button(action: {
                                    DispatchQueue.main.async {
                                        HapticManager.shared.light()
                                    }
                                    showSaveButton = false
                                    recordedVideoURL = nil
                                    hasStartedRecording = false
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        .scaleEffect(1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSaveButton)
                                }
                                
                                Spacer()
                                
                                // Professional confirm button with accent color
                                Button(action: {
                                    DispatchQueue.main.async {
                                        HapticManager.shared.medium()
                                    }
                                    // Show rating popup instead of saving immediately
                                    showRatingPopup = true
                                }) {
                                    ZStack {
                                        // Outer ring with white glow
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                            .frame(width: 84, height: 84)
                                            .scaleEffect(1.0)
                                            .opacity(1.0)
                                        
                                        // Main button with accent color gradient
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [appState.accentColor.swiftUIColor, appState.accentColor.swiftUIColor.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 74, height: 74)
                                            .shadow(
                                                color: appState.accentColor.swiftUIColor.opacity(0.4),
                                                radius: 8,
                                                x: 0,
                                                y: 4
                                            )
                                            .scaleEffect(1.0)
                                        
                                        // Checkmark icon
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                    }
                                }
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSaveButton)
                                .offset(x: 11)
                                
                                Spacer()
                                
                                Color.clear.frame(width: 56, height: 56)
                            }
                            .padding(.horizontal, 32)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.1)),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        }
                        
                        // Record/Recording State
                        if !showSaveButton {
                            if videoManager.hasRecordedToday() {
                                // Greyed out button when already recorded today
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(appState.isLowercaseMode ? "Today's entry was already recorded".lowercased() : "Today's entry was already recorded")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                                }
                            } else {
                                // Professional record button
                                Button(action: {
                                    if videoManager.isRecording {
                                        DispatchQueue.main.async {
                                            HapticManager.shared.rigid()
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            HapticManager.shared.medium()
                                        }
                                        hasStartedRecording = true
                                    }
                                    toggleRecording()
                                }) {
                                    ZStack {
                                        // Outer ring with accent color when recording, white when idle
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: videoManager.isRecording ?
                                                        [appState.accentColor.swiftUIColor.opacity(0.8), appState.accentColor.swiftUIColor.opacity(0.4)] :
                                                        [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                            .frame(width: 84, height: 84)
                                            .scaleEffect(videoManager.isRecording ? 1.05 : 1.0)
                                            .opacity(videoManager.isRecording ? 0.8 : 1.0)
                                        
                                        // Main button with accent color gradient
                                        Circle()
                                            .fill(
                                                videoManager.isRecording ? 
                                                    LinearGradient(
                                                        colors: [appState.accentColor.swiftUIColor, appState.accentColor.swiftUIColor.opacity(0.8)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [Color.white, Color.white.opacity(0.9)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                            .frame(width: 74, height: 74)
                                            .shadow(
                                                color: videoManager.isRecording ? 
                                                    appState.accentColor.swiftUIColor.opacity(0.4) :
                                                    Color.black.opacity(0.2),
                                                radius: videoManager.isRecording ? 8 : 4,
                                                x: 0,
                                                y: videoManager.isRecording ? 4 : 2
                                            )
                                            .scaleEffect(videoManager.isRecording ? 0.95 : 1.0)
                                        
                                        // Inner content
                                        if videoManager.isRecording {
                                            // Stop icon (rounded rectangle)
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.white)
                                                .frame(width: 28, height: 28)
                                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                        } else {
                                            // Record dot indicator
                                            Circle()
                                                .fill(appState.accentColor.swiftUIColor.opacity(0.8))
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                                .scaleEffect(videoManager.isRecording ? 1.0 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: videoManager.isRecording)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 1.1)),
                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                ))
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Rating Popup Overlay
            if showRatingPopup {
                RatingPopup(
                    onRate: { rating in
                        selectedRating = rating
                        showRatingPopup = false
                        
                        // Save video with rating
                        if let url = recordedVideoURL {
                            videoManager.saveVideo(url: url, rating: rating)
                            streakManager.recordVideo()
                            appState.recordedToday()
                            
                            // Reset state
                            showSaveButton = false
                            recordedVideoURL = nil
                            selectedRating = nil
                            
                            // Switch to calendar tab
                            onVideoSaved?()
                        }
                    },
                    onSkip: {
                        showRatingPopup = false
                        
                        // Save video without rating
                        if let url = recordedVideoURL {
                            videoManager.saveVideo(url: url, rating: nil)
                            streakManager.recordVideo()
                            appState.recordedToday()
                            
                            // Reset state
                            showSaveButton = false
                            recordedVideoURL = nil
                            
                            // Switch to calendar tab
                            onVideoSaved?()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRatingPopup)
        .onChange(of: showRatingPopup) { isShowing in
            if isShowing {
                // Stop camera when rating popup appears (allows haptics to work)
                cameraManager.stopCamera()
            }
        }
        .onAppear {
            // Always kill and restart camera to prevent frozen feed
            cameraManager.restartCamera(useFront: isFrontCamera)
            
            // Reset recording state to ensure clean start
            showSaveButton = false
            recordedVideoURL = nil
            hasStartedRecording = false
            recordingSegments.removeAll()
            isProcessingCameraSwitch = false
            
            // Prepare haptics for immediate use
            HapticManager.shared.prepareLight()
            HapticManager.shared.prepareMedium()
            HapticManager.shared.prepareRigid()
            // Randomize daily prompt
            dailyPrompt = dailyPrompts.randomElement() ?? dailyPrompts[0]
        }
        .onDisappear {
            cameraManager.stopCamera()
            // Clean up any pending recording segments
            recordingSegments.removeAll()
            isProcessingCameraSwitch = false
        }
    }
    
    private func toggleRecording() {
        if videoManager.isRecording {
            print("Stopping recording")
            videoManager.stopRecording()
            cameraManager.stopRecording { url in
                DispatchQueue.main.async {
                    print("Recording stopped - URL: \(url?.absoluteString ?? "nil")")
                    
                    // Add the final segment
                    if let url = url {
                        self.recordingSegments.append(url)
                    }
                    
                    // If we have multiple segments, combine them
                    if self.recordingSegments.count > 1 {
                        print("Combining \(self.recordingSegments.count) recording segments")
                        self.combineVideoSegments(self.recordingSegments) { combinedURL in
                            DispatchQueue.main.async {
                                if let combinedURL = combinedURL {
                                    self.recordedVideoURL = combinedURL
                                    self.showSaveButton = true
                                    print("Combined video ready - showSaveButton set to true")
                                } else {
                                    print("Failed to combine video segments - using first segment as fallback")
                                    // Fallback: use the first segment if combination fails
                                    if let firstSegment = self.recordingSegments.first {
                                        self.recordedVideoURL = firstSegment
                                        self.showSaveButton = true
                                    } else {
                                        print("Critical error: No segments available for fallback")
                                        // Reset to allow user to try recording again
                                        self.hasStartedRecording = false
                                    }
                                }
                                // Clean up segments
                                self.recordingSegments.removeAll()
                            }
                        }
                    } else if let singleURL = self.recordingSegments.first {
                        // Single segment, use directly
                        self.recordedVideoURL = singleURL
                        self.showSaveButton = true
                        self.recordingSegments.removeAll()
                        print("Single segment recording - showSaveButton set to true")
                    } else {
                        print("No recording segments found - this should not happen")
                        // Reset state to allow user to try again
                        self.hasStartedRecording = false
                    }
                }
            }
        } else {
            print("Starting recording")
            recordingSegments.removeAll() // Clear any previous segments
            videoManager.startRecording()
            cameraManager.startRecording(maxDuration: maxRecordingDuration)
        }
    }
    
    private func flipCamera() {
        if videoManager.isRecording {
            print("Flipping camera during recording - using segmented approach")
            switchCameraDuringRecording()
        } else {
            isFrontCamera.toggle()
            cameraManager.switchCamera(toFront: isFrontCamera)
        }
    }
    
    private func switchCameraDuringRecording() {
        guard !isProcessingCameraSwitch else {
            print("Already processing camera switch - ignoring")
            return
        }
        
        guard videoManager.isRecording else {
            print("Not recording - switching to normal camera flip")
            flipCamera()
            return
        }
        
        isProcessingCameraSwitch = true
        
        // Step 1: Stop current recording and save segment
        cameraManager.stopRecording { url in
            DispatchQueue.main.async {
                
                if let url = url {
                    self.recordingSegments.append(url)
                    print("Saved recording segment: \(url.lastPathComponent)")
                }
                
                // Step 2: Switch camera
                self.isFrontCamera.toggle()
                self.cameraManager.switchCamera(toFront: self.isFrontCamera)
                
                // Step 3: Start new recording segment after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.cameraManager.startRecording(maxDuration: self.maxRecordingDuration)
                    self.isProcessingCameraSwitch = false
                    print("Started new recording segment with \(self.isFrontCamera ? "front" : "back") camera")
                }
            }
        }
    }
    
    private func combineVideoSegments(_ segments: [URL], completion: @escaping (URL?) -> Void) {
        guard !segments.isEmpty else {
            completion(nil)
            return
        }
        
        guard segments.count > 1 else {
            completion(segments.first)
            return
        }
        
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        let videoComposition = AVMutableVideoComposition()
        var instructions: [AVMutableVideoCompositionInstruction] = []
        var currentTime = CMTime.zero
        
        // Get the first video track to determine output size
        let firstAsset = AVAsset(url: segments[0])
        guard let firstVideoTrack = firstAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        
        let outputSize = firstVideoTrack.naturalSize
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
        
        for segmentURL in segments {
            let asset = AVAsset(url: segmentURL)
            
            // Add video track
            if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                do {
                    let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                    try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: currentTime)
                    
                    // Create video composition instruction for this segment
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(start: currentTime, duration: asset.duration)
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                    
                    // Apply transform to maintain consistent orientation
                    let transform = assetVideoTrack.preferredTransform
                    layerInstruction.setTransform(transform, at: currentTime)
                    
                    instruction.layerInstructions = [layerInstruction]
                    instructions.append(instruction)
                    
                } catch {
                    print("Error inserting video track: \(error)")
                    completion(nil)
                    return
                }
            }
            
            // Add audio track
            if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
                do {
                    let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                    try audioTrack.insertTimeRange(timeRange, of: assetAudioTrack, at: currentTime)
                } catch {
                    print("Error inserting audio track: \(error)")
                    // Continue without audio for this segment
                }
            }
            
            currentTime = CMTimeAdd(currentTime, asset.duration)
        }
        
        videoComposition.instructions = instructions
        
        // Export the combined video
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("Video segments combined successfully")
                    completion(outputURL)
                case .failed:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                case .cancelled:
                    print("Export cancelled")
                    completion(nil)
                default:
                    completion(nil)
                }
                
                // Clean up temporary segment files
                for segmentURL in segments {
                    try? FileManager.default.removeItem(at: segmentURL)
                }
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RatingPopup: View {
    let onRate: (Int) -> Void
    let onSkip: () -> Void
    @State private var selectedRating: Int? = nil
    @EnvironmentObject var appState: AppState
    
    private func ratingColor(for rating: Int) -> Color {
        switch rating {
        case 1...2: return Color(red: 0.5, green: 0, blue: 0)
        case 3...4: return .red
        case 5...6: return .orange
        case 7...8: return .yellow
        case 9...10: return .green
        default: return .gray
        }
    }
    
    private func ratingButton(for rating: Int) -> some View {
        Button(action: {
            HapticManager.shared.light()
            selectedRating = rating
        }) {
            Text("\(rating)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 36, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedRating == rating ? ratingColor(for: rating) : Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedRating == rating ? ratingColor(for: rating) : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        // Popup content (no dim background - camera is stopped instead)
        VStack(spacing: 24) {
            Text(appState.isLowercaseMode ? "How was your day?".lowercased() : "How was your day?")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(appState.isLowercaseMode ? "Rate today from 1 to 10".lowercased() : "Rate today from 1 to 10")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
            
            // Rating buttons - two rows of 1-10
            VStack(spacing: 8) {
                // Row 1: 1-5
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { rating in
                        ratingButton(for: rating)
                    }
                }
                // Row 2: 6-10
                HStack(spacing: 8) {
                    ForEach(6...10, id: \.self) { rating in
                        ratingButton(for: rating)
                    }
                }
            }
            
            // Confirm button
            Button(action: {
                if let rating = selectedRating {
                    HapticManager.shared.medium()
                    onRate(rating)
                }
            }) {
                Text(appState.isLowercaseMode ? "Save Entry".lowercased() : "Save Entry")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedRating != nil ? Color.white : Color.gray)
                    )
            }
            .disabled(selectedRating == nil)
            .buttonStyle(PlainButtonStyle())
            
            // Skip button
            Button(action: {
                HapticManager.shared.light()
                onSkip()
            }) {
                Text(appState.isLowercaseMode ? "Skip".lowercased() : "Skip")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        return cameraManager.previewView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        cameraManager.updatePreviewFrame()
    }
}

class CameraManager: NSObject, ObservableObject {
    let previewView = UIView()
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var completionHandler: ((URL?) -> Void)?
    
    private var currentVideoInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false
    
    // Cache optimal format for performance
    private var cachedFormat: AVCaptureDevice.Format?
    private var cachedDevice: AVCaptureDevice?
    
    func setupCamera(useFront: Bool = true) {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Set 1920x1080 preset for optimal quality/size balance
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        // Add video input (front camera default)
        let position: AVCaptureDevice.Position = useFront ? .front : .back
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: useFront ? .back : .front)
        
        guard let device = videoDevice else { return }
        
        // Configure device for optimal performance
        configureDevice(device)
        
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        currentVideoInput = videoInput
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add audio input with optimized settings
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Add video output with optimized compression
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            // Configure video compression for optimal file size
            if let connection = videoOutput.connection(with: .video) {
                // Enable video stabilization
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                
                // Set video orientation to portrait
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                
                // Mirror front camera to match what user sees in preview
                if connection.isVideoMirroringSupported {
                    let position = (try? AVCaptureDeviceInput(device: device))?.device.position
                    connection.isVideoMirrored = (position == .front)
                }
            }
        }
        
        captureSession.commitConfiguration()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspect
        previewLayer?.frame = previewView.bounds
        
        if let previewLayer = previewLayer {
            previewView.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func switchCamera(toFront: Bool) {
        guard let captureSession = captureSession else { return }
        
        // This method should only be called when not recording
        guard !(videoOutput?.isRecording ?? false) else {
            print("Warning: Attempted to switch camera during recording - use switchCameraDuringRecording instead")
            return
        }
        
        captureSession.beginConfiguration()
        
        // Remove existing video input
        if let currentInput = currentVideoInput {
            captureSession.removeInput(currentInput)
        }
        
        // Add new video input
        let position: AVCaptureDevice.Position = toFront ? .front : .back
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: toFront ? .back : .front)
        
        guard let device = videoDevice else {
            captureSession.commitConfiguration()
            return
        }
        
        // Configure the new device
        configureDevice(device)
        
        guard let videoInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentVideoInput = videoInput
        captureSession.addInput(videoInput)
        
        // Re-configure video output connection after switching camera
        if let videoOutput = videoOutput, let connection = videoOutput.connection(with: .video) {
            // Enable video stabilization
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            // Set video orientation to portrait
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // Mirror front camera to match what user sees in preview
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = toFront
            }
        }
        
        captureSession.commitConfiguration()
        print("Camera switched successfully to \(toFront ? "front" : "back")")
    }
    
    func switchCameraDuringRecording(toFront: Bool) {
        guard let captureSession = captureSession,
              let videoOutput = videoOutput else { return }
        
        // Check if we're actually recording
        guard videoOutput.isRecording else {
            print("Not currently recording - using regular switch")
            switchCamera(toFront: toFront)
            return
        }
        
        print("Switching camera during recording - this may cause a brief interruption")
        
        // We need to be very careful here - switching inputs during recording can be tricky
        // The safest approach is to quickly switch the input while keeping the session running
        
        captureSession.beginConfiguration()
        
        // Remove existing video input
        if let currentInput = currentVideoInput {
            captureSession.removeInput(currentInput)
        }
        
        // Add new video input
        let position: AVCaptureDevice.Position = toFront ? .front : .back
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: toFront ? .back : .front)
        
        guard let device = videoDevice else {
            captureSession.commitConfiguration()
            print("Failed to get camera device")
            return
        }
        
        // Configure the new device
        configureDevice(device)
        
        guard let videoInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            print("Failed to create or add video input")
            return
        }
        
        currentVideoInput = videoInput
        captureSession.addInput(videoInput)
        
        // Re-configure video output connection after switching camera
        if let connection = videoOutput.connection(with: .video) {
            // Enable video stabilization
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            // Set video orientation to portrait
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // Mirror front camera to match what user sees in preview
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = toFront
            }
        }
        
        captureSession.commitConfiguration()
        print("Camera switched during recording to \(toFront ? "front" : "back")")
    }
    
    func updatePreviewFrame() {
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.previewView.bounds
        }
    }
    
    func stopCamera() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
            
            DispatchQueue.main.async {
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
                // Don't nil the session - reuse it for better performance
                self.isSessionConfigured = false
            }
        }
    }
    
    func restartCamera(useFront: Bool = true) {
        // Completely kill the existing session to prevent frozen feeds
        if let captureSession = captureSession {
            DispatchQueue.global(qos: .userInitiated).async {
                if captureSession.isRunning {
                    captureSession.stopRunning()
                }
                
                DispatchQueue.main.async {
                    self.previewLayer?.removeFromSuperlayer()
                    self.previewLayer = nil
                    self.captureSession = nil
                    self.videoOutput = nil
                    self.currentVideoInput = nil
                    self.isSessionConfigured = false
                    
                    // Setup fresh camera session
                    self.setupCamera(useFront: useFront)
                }
            }
        } else {
            setupCamera(useFront: useFront)
        }
    }
    
    private func configureDevice(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Use cached format if available and device matches
            if cachedDevice == device, let format = cachedFormat {
                device.activeFormat = format
            } else {
                // Find optimal format (prefer higher resolution, 30fps)
                let optimalFormat = device.formats
                    .filter { format in
                        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                        return dimensions.width >= 1920 && dimensions.height >= 1080
                    }
                    .sorted { format1, format2 in
                        let dims1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
                        let dims2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
                        return dims1.width * dims1.height > dims2.width * dims2.height
                    }
                    .first
                
                if let format = optimalFormat {
                    device.activeFormat = format
                    cachedFormat = format
                    cachedDevice = device
                }
            }
            
            // Set 30fps
            let desiredFPS = 30.0
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
            
            // Enable continuous autofocus for smoother video
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Enable auto exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }
    
    func startRecording(maxDuration: TimeInterval) {
        guard let videoOutput = videoOutput else { return }
        
        // Set max duration
        videoOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 1)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        completionHandler = completion
        videoOutput?.stopRecording()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        completionHandler?(error == nil ? outputFileURL : nil)
        completionHandler = nil
    }
}

#Preview {
    RecordingView()
        .environmentObject(VideoManager())
        .environmentObject(StreakManager())
}
