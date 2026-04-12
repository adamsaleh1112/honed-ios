import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTime = Date()
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()
            
            VStack(spacing: 40) {
                switch currentStep {
                case 0:
                    WelcomeStep()
                case 1:
                    NotificationStep()
                default:
                    CompletionStep()
                }
                
                Spacer()
                
                Button(action: nextStep) {
                    Text(currentStep == 2 ? "Start your journey" : "Continue")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(24)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func WelcomeStep() -> some View {
        VStack(spacing: 30) {
            Text("Talk to your future self.")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                FeatureRow(icon: "video.fill", text: "Record daily video logs")
                FeatureRow(icon: "flame.fill", text: "Build consistency streaks")
                FeatureRow(icon: "clock.fill", text: "Max 10 minutes per day")
                FeatureRow(icon: "heart.fill", text: "Watch yourself grow")
            }
        }
    }
    
    @ViewBuilder
    private func NotificationStep() -> some View {
        VStack(spacing: 30) {
            Text("Daily reminder")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
            
            Text("When should we remind you to record?")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            DatePicker("Notification Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .colorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func CompletionStep() -> some View {
        VStack(spacing: 30) {
            Text("You're ready!")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
            
            Text("Don't let your life go unrecorded.")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Text("Remember:")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text("• Show up every day")
                Text("• Speak honestly")
                Text("• Watch yourself grow")
            }
            .font(.system(size: 16))
            .foregroundColor(.gray)
        }
    }
    
    private func nextStep() {
        if currentStep < 2 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Complete onboarding
            appState.isOnboarded = true
            appState.saveUserDefaults()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
}
