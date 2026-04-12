import Foundation

struct VideoEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let videoFilename: String
    let duration: TimeInterval
    let thumbnailFilename: String?
    
    init(id: UUID? = nil, date: Date, videoFilename: String, duration: TimeInterval, thumbnailFilename: String? = nil) {
        self.id = id ?? UUID()
        self.date = date
        self.videoFilename = videoFilename
        self.duration = duration
        self.thumbnailFilename = thumbnailFilename
    }
    
    // Computed property to get full URL from filename
    var videoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(videoFilename)
    }
    
    var thumbnailURL: URL? {
        thumbnailFilename.map { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent($0) }
    }
    
    var daysSinceRecording: Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
    
    var isFromToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var isFromYesterday: Bool {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return Calendar.current.isDate(date, inSameDayAs: yesterday)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
