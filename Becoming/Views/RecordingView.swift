import SwiftUI
import AVFoundation

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var appState: AppState
    
    @StateObject private var cameraManager = CameraManager()
    @State private var showingRetakeAlert = false
    @State private var hasAttemptedRecording = false
    @State private var recordedVideoURL: URL?
    @State private var showSaveButton = false
    @State private var isFrontCamera = true
    
    private let maxRecordingDuration: TimeInterval = 600 // 10 minutes
    
    var body: some View {
        ZStack {
            // Full screen camera preview at back
            ZStack {
                Color.black
                CameraPreviewView(cameraManager: cameraManager)
            }
            .ignoresSafeArea()
            .onAppear {
                cameraManager.updatePreviewFrame()
            }
            
            // UI Overlay
            VStack {
                // Header with duration counter
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    // Duration counter with subtle animation
                    if videoManager.isRecording || hasAttemptedRecording {
                        Text("\(formatTime(videoManager.recordingDuration)) / \(formatTime(maxRecordingDuration))")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.easeInOut(duration: 0.15), value: videoManager.recordingDuration)
                    }
                    
                    Spacer()
                    
                    // Camera flip button
                    if !videoManager.isRecording && !showSaveButton {
                        Button(action: flipCamera) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    } else {
                        // Spacer for balance when button hidden
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Recording Controls
                VStack(spacing: 20) {
                    // Show Save Button after recording
                    if showSaveButton, let url = recordedVideoURL {
                        VStack(spacing: 16) {
                            Text("Recording Complete")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                videoManager.saveVideo(url: url)
                                streakManager.recordVideo()
                                dismiss()
                            }) {
                                Text("Add Video Entry")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Retake - reset and go again
                                showSaveButton = false
                                recordedVideoURL = nil
                                hasAttemptedRecording = false
                            }) {
                                Text("Retake")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        // Record Button
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(videoManager.isRecording ? Color.red : Color.white)
                                    .frame(width: 80, height: 80)
                                
                                if videoManager.isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        .disabled(appState.oneTakeMode && hasAttemptedRecording && !videoManager.isRecording)
                        .opacity((appState.oneTakeMode && hasAttemptedRecording && !videoManager.isRecording) ? 0.5 : 1.0)
                        
                        // Instructions
                        Text(getInstructionText())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraManager.setupCamera()
        }
        .alert("One Take Mode", isPresented: $showingRetakeAlert) {
            Button("Keep Recording", role: .cancel) { }
            Button("Save & Exit") {
                saveAndExit()
            }
        } message: {
            Text("You can only record once in One Take Mode. Save this recording or keep going?")
        }
    }
    
    private func toggleRecording() {
        if videoManager.isRecording {
            videoManager.stopRecording()
            cameraManager.stopRecording { url in
                if let url = url {
                    recordedVideoURL = url
                    showSaveButton = true
                    
                    if appState.oneTakeMode {
                        showingRetakeAlert = true
                    }
                }
            }
        } else {
            if appState.oneTakeMode && hasAttemptedRecording {
                return // Can't record again in one take mode
            }
            
            hasAttemptedRecording = true
            videoManager.startRecording()
            cameraManager.startRecording(maxDuration: maxRecordingDuration)
        }
    }
    
    private func flipCamera() {
        isFrontCamera.toggle()
        cameraManager.switchCamera(toFront: isFrontCamera)
    }
    
    private func saveAndExit() {
        dismiss()
    }
    
    private func getInstructionText() -> String {
        if appState.oneTakeMode && hasAttemptedRecording && !videoManager.isRecording {
            return "One take complete. Tap 'Save & Exit' to finish."
        } else if videoManager.isRecording {
            return "Recording... Tap to stop (max 10 minutes)"
        } else {
            return "Tap to start recording your daily log"
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
    
    func setupCamera(useFront: Bool = true) {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Add video input (front camera default)
        let position: AVCaptureDevice.Position = useFront ? .front : .back
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: useFront ? .back : .front)
        
        guard let device = videoDevice,
              let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        currentVideoInput = videoInput
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Add video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
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
        
        captureSession.beginConfiguration()
        
        // Remove existing video input
        if let currentInput = currentVideoInput {
            captureSession.removeInput(currentInput)
        }
        
        // Add new video input
        let position: AVCaptureDevice.Position = toFront ? .front : .back
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: toFront ? .back : .front)
        
        guard let device = videoDevice,
              let videoInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentVideoInput = videoInput
        captureSession.addInput(videoInput)
        captureSession.commitConfiguration()
    }
    
    func updatePreviewFrame() {
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.previewView.bounds
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
        .environmentObject(AppState())
}
