import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTime = Date()
    @State private var currentStep = 0
    @State private var userName = ""

    var body: some View {
        ZStack {
            appState.theme.background.ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Animated content area
                VStack(spacing: 40) {
                    Group {
                        switch currentStep {
                        case 0:
                            WelcomeStep()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(x: 50)),
                                    removal: .opacity.combined(with: .offset(x: -50))
                                ))
                        case 1:
                            NotificationStep()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(x: 50)),
                                    removal: .opacity.combined(with: .offset(x: -50))
                                ))
                        case 2:
                            NameStep()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(x: 50)),
                                    removal: .opacity.combined(with: .offset(x: -50))
                                ))
                        default:
                            CompletionStep()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                    removal: .opacity.combined(with: .scale(scale: 1.1))
                                ))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Button with animation
                Button(action: nextStep) {
                    Text(buttonText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(currentStep == 3 ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Group {
                                if currentStep == 3 {
                                    RoundedRectangle(cornerRadius: 40)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.051, green: 0.271, blue: 0.675), // #0D45AC
                                                    Color(red: 0.922, green: 0.624, blue: 0.961)  // #EB9FF5
                                                ]),
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 40)
                                        .fill(Color.white)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        )
                }
                .padding(.horizontal, 24)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 20)),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
            }
            .padding(.vertical, 40)
        }
    }
    
    @ViewBuilder
    private func WelcomeStep() -> some View {
        VStack(spacing: 50) {
            Text("Talk to your future self.")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            VStack(spacing: 24) {
                FeatureRow(icon: "video.fill", text: "Record daily video logs")
                FeatureRow(icon: "flame.fill", text: "Build consistency streaks")
                FeatureRow(icon: "clock.fill", text: "Max 10 minutes per day")
                FeatureRow(icon: "heart.fill", text: "Watch yourself grow")
            }
            .transition(.opacity.combined(with: .offset(y: 20)))
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func NotificationStep() -> some View {
        VStack(spacing: 50) {
            Text("Daily reminder")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            Text("When should we remind you to record?")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .offset(y: 15)))
            
            DatePicker("Notification Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .colorScheme(.dark)
                .frame(maxWidth: 320)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func NameStep() -> some View {
        VStack(spacing: 50) {
            Text("What's your name?")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            TextField("Enter name", text: $userName)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                // .background(
                //     RoundedRectangle(cornerRadius: 16)
                //         .fill(Color.white.opacity(0.08))
                // )
                // .overlay(
                //     RoundedRectangle(cornerRadius: 16)
                //         .stroke(Color.white.opacity(0.12), lineWidth: 1)
                // )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func CompletionStep() -> some View {
        VStack(spacing: 50) {
            Text("You're ready!")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            
            Text("Don't let your life go unrecorded.")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .offset(y: 15)))
            
            // VStack(alignment: .leading, spacing: 20) {
            //     Text("Remember:")
            //         .font(.system(size: 20, weight: .semibold, design: .rounded))
            //         .foregroundColor(.white)
                
            //     VStack(alignment: .leading, spacing: 12) {
            //         Text("• Show up every day")
            //         Text("• Speak honestly")
            //         Text("• Watch yourself grow")
            //     }
            //     .font(.system(size: 18))
            //     .foregroundColor(.gray)
            // }
            // .transition(.opacity.combined(with: .offset(y: 20)))
        }
        .padding(.horizontal, 32)
    }
    
    private var buttonText: String {
        switch currentStep {
        case 2: // Name step
            return userName.isEmpty ? "Skip" : "Continue"
        case 3: // Completion step
            return "Start your journey"
        default:
            return "Continue"
        }
    }
    
    private func nextStep() {
        // Soft haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if currentStep < 3 {
            // Save notification time after step 1 and request permission
            if currentStep == 1 {
                // appState.notificationTime = selectedTime
                // Request notification permission now that user has selected a time
                notificationManager.requestPermission()
                notificationManager.scheduleDailyNotification(at: selectedTime, streak: 0, userName: appState.userName)
            }
            // Save name after step 2 (only if not empty)
            else if currentStep == 2 && !userName.isEmpty {
                appState.userName = userName
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
