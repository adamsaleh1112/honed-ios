import Foundation
import AVFoundation
import Photos
import UIKit

class VideoManager: ObservableObject {
    @Published var videoEntries: [VideoEntry] = []
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    
    private let maxRecordingDuration: TimeInterval = 600 // 10 minutes
    private var recordingTimer: Timer?
    
    init() {
        loadVideoEntries()
    }
    
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.recordingDuration += 1.0
            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func saveVideo(url: URL) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let fileName = "video_\(timestamp).mov"
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Generate thumbnail
            let thumbnailFilename = generateThumbnail(for: destinationURL, timestamp: timestamp)
            
            // Create VideoEntry with relative paths (filenames only)
            let videoEntry = VideoEntry(
                date: Date(),
                videoFilename: fileName,
                duration: recordingDuration,
                thumbnailFilename: thumbnailFilename
            )
            
            videoEntries.insert(videoEntry, at: 0)
            saveVideoEntries()
            
        } catch {
            print("Error saving video: \(error)")
        }
    }
    
    private func generateThumbnail(for videoURL: URL, timestamp: TimeInterval) -> String? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            
            let filename = "thumb_\(timestamp).jpg"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let thumbnailURL = documentsPath.appendingPathComponent(filename)
            
            if let data = image.jpegData(compressionQuality: 0.7) {
                try data.write(to: thumbnailURL)
                return filename
            }
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        
        return nil
    }
    
    func getVideoForDate(_ date: Date) -> VideoEntry? {
        return videoEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func hasRecordedToday() -> Bool {
        return getVideoForDate(Date()) != nil
    }
    
    func getVideosFromLastYear() -> [VideoEntry] {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return videoEntries.filter { $0.date >= oneYearAgo }
    }
    
    func getVideoFromSameDateLastYear() -> VideoEntry? {
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return videoEntries.first { Calendar.current.isDate($0.date, inSameDayAs: lastYear) }
    }
    
    private func loadVideoEntries() {
        if let data = UserDefaults.standard.data(forKey: "videoEntries"),
           let entries = try? JSONDecoder().decode([VideoEntry].self, from: data) {
            videoEntries = entries.sorted { $0.date > $1.date }
        }
    }
    
    private func saveVideoEntries() {
        if let data = try? JSONEncoder().encode(videoEntries) {
            UserDefaults.standard.set(data, forKey: "videoEntries")
        }
    }
    
    func deleteVideo(_ entry: VideoEntry) {
        if let index = videoEntries.firstIndex(where: { $0.id == entry.id }) {
            videoEntries.remove(at: index)
            
            // Delete the actual files
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try? FileManager.default.removeItem(at: documentsPath.appendingPathComponent(entry.videoFilename))
            if let thumbnailFilename = entry.thumbnailFilename {
                try? FileManager.default.removeItem(at: documentsPath.appendingPathComponent(thumbnailFilename))
            }
            
            saveVideoEntries()
        }
    }
}
