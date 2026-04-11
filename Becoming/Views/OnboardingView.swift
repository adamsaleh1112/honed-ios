import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTime = Date()
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                switch currentStep {
                case 0:
                    WelcomeStep()
                case 1:
                    NotificationStep()
                case 2:
                    OneTakeModeStep()
                default:
                    CompletionStep()
                }
                
                Spacer()
                
                Button(action: nextStep) {
                    Text(currentStep == 3 ? "Start your journey" : "Continue")
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
    private func OneTakeModeStep() -> some View {
        VStack(spacing: 30) {
            Text("One take mode")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
            
            Text("Force authenticity by limiting retakes")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Toggle("Enable one take mode", isOn: $appState.oneTakeMode)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text("When enabled, you only get one attempt to record. This reduces perfectionism and keeps your logs authentic.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
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
        if currentStep < 3 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Complete onboarding
            appState.notificationTime = selectedTime
            notificationManager.scheduleDailyNotification(at: selectedTime, streak: 0)
            appState.completeOnboarding()
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
