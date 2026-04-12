import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare all generators upfront
        lightGenerator.prepare()
        mediumGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func light() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
    }
    
    func medium() {
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
    }
    
    func soft() {
        softGenerator.prepare()
        softGenerator.impactOccurred()
    }
    
    func rigid() {
        rigidGenerator.prepare()
        rigidGenerator.impactOccurred()
    }
    
    func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warning() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func error() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)
    }
    
    func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }
    
    // Preemptively prepare generators before user interaction
    func prepareLight() {
        lightGenerator.prepare()
    }
    
    func prepareMedium() {
        mediumGenerator.prepare()
    }
    
    func prepareSoft() {
        softGenerator.prepare()
    }
}
