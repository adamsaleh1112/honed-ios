import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthState
    @StateObject private var onboardingFlow = OnboardingFlow()
    
    var body: some View {
        ZStack {
            appState.theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(progressColor(for: index))
                            .frame(width: index == currentStepIndex ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentStepIndex)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                // Content
                VStack {
                    switch authState.currentStep {
                    case .auth:
                        AuthView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 50)),
                                removal: .opacity.combined(with: .offset(x: -50))
                            ))
                    case .routineBuilder:
                        RoutineBuilderView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 50)),
                                removal: .opacity.combined(with: .offset(x: -50))
                            ))
                    case .restDays:
                        RestDaysView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 50)),
                                removal: .opacity.combined(with: .offset(x: -50))
                            ))
                    case .complete:
                        CompletionStep()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                removal: .opacity.combined(with: .scale(scale: 1.1))
                            ))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authState.currentStep)
                
                Spacer()
            }
        }
    }
    
    private var currentStepIndex: Int {
        switch authState.currentStep {
        case .auth: return 0
        case .routineBuilder: return 1
        case .restDays: return 2
        case .complete: return 2
        }
    }
    
    private func progressColor(for index: Int) -> Color {
        if index <= currentStepIndex {
            return appState.accentColor.swiftUIColor
        }
        return appState.theme.textMuted.opacity(0.3)
    }
}

struct CompletionStep: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthState
    
    var body: some View {
        VStack(spacing: 50) {
            Text("YOU'RE READY")
                .font(.system(size: 38, weight: .regular))
                .fontWidth(.expanded)
                .foregroundColor(appState.theme.textPrimary)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            
            Text("Start your journey.")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(appState.theme.textSecondary)
                .transition(.opacity.combined(with: .offset(y: 15)))
            
            Button(action: {
                HapticManager.shared.heavy()
                withAnimation(.easeInOut(duration: 0.6)) {
                    appState.isOnboarded = true
                }
                appState.saveUserDefaults()
            }) {
                Text("Start your journey")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        AnimatedMeshGradientBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 20)),
                removal: .opacity
            ))
        }
        .padding(.horizontal, 32)
    }
}

class OnboardingFlow: ObservableObject {
    // Placeholder for any shared onboarding state
}

struct DarkMeshGradientBackground: View {
    @State private var phase: Float = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { _ in
            MeshGradient(
                width: 5,
                height: 5,
                points: [
                    // Row 0 (top) - all black edges
                    [0.0, 0.0], [0.25, 0.0], [0.5, 0.0], [0.75, 0.0], [1.0, 0.0],
                    // Row 1 - outer black, inner starts glowing
                    [0.0, 0.25], [0.25, 0.25], [animatedX(0.35, 0.65), animatedY(0.15, 0.35)], [0.75, 0.25], [1.0, 0.25],
                    // Row 2 - center with moving green glow
                    [0.0, 0.5], [animatedX(0.15, 0.35), animatedY(0.35, 0.65)], [animatedCenterX, animatedCenterY], [animatedX(0.65, 0.85), animatedY(0.35, 0.65)], [1.0, 0.5],
                    // Row 3 - outer black, inner glow
                    [0.0, 0.75], [0.25, 0.75], [animatedX(0.35, 0.65), animatedY(0.65, 0.85)], [0.75, 0.75], [1.0, 0.75],
                    // Row 4 (bottom) - all black edges
                    [0.0, 1.0], [0.25, 1.0], [0.5, 1.0], [0.75, 1.0], [1.0, 1.0]
                ],
                colors: [
                    // Corners and edges - pure black
                    .black, .black, .black, .black, .black,
                    .black, darkGreenGlow(0.3), brightGreenGlow(0.7), darkGreenGlow(0.3), .black,
                    .black, brightGreenGlow(0.5), brightGreenGlow(1.0), brightGreenGlow(0.5), .black,
                    .black, darkGreenGlow(0.3), brightGreenGlow(0.7), darkGreenGlow(0.3), .black,
                    .black, .black, .black, .black, .black
                ]
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
    
    private var animatedCenterX: Float {
        0.5 + sin(phase) * 0.15
    }
    
    private var animatedCenterY: Float {
        0.5 + cos(phase * 0.7) * 0.15
    }
    
    private func animatedX(_ min: Float, _ max: Float) -> Float {
        let offset = sin(phase + 1.0) * 0.08
        return (min + max) / 2 + offset
    }
    
    private func animatedY(_ min: Float, _ max: Float) -> Float {
        let offset = cos(phase * 1.3 + 2.0) * 0.08
        return (min + max) / 2 + offset
    }
    
    private func brightGreenGlow(_ intensity: Double) -> Color {
        Color(
            red: 0.02 + 0.06 * intensity,
            green: 0.08 + 0.12 * intensity,
            blue: 0.01 + 0.04 * intensity
        )
    }
    
    private func darkGreenGlow(_ intensity: Double) -> Color {
        Color(
            red: 0.03 * intensity,
            green: 0.06 * intensity,
            blue: 0.02 * intensity
        )
    }
}

struct AnimatedMeshGradientBackground: View {
    @State private var isAnimating = false
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.2 : 0.8, isAnimating ? 0.3 : 0.7], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.5, green: 0.7, blue: 0.15),
                Color(red: 0.69, green: 0.851, blue: 0.212),
                Color(red: 0.8, green: 0.9, blue: 0.35),
                Color(red: 0.6, green: 0.78, blue: 0.18),
                isAnimating ? Color(red: 0.75, green: 0.88, blue: 0.3) : Color(red: 0.65, green: 0.82, blue: 0.25),
                Color(red: 0.8, green: 0.9, blue: 0.35),
                Color(red: 0.69, green: 0.851, blue: 0.212),
                Color(red: 0.6, green: 0.78, blue: 0.18),
                Color(red: 0.5, green: 0.7, blue: 0.15)
            ]
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .environmentObject(AuthState())
}
