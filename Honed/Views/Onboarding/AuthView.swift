import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            DarkMeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 40) {
                    // Title
                    VStack(spacing: 12) {
                        Text(isLogin ? "WELCOME BACK" : "CREATE ACCOUNT")
                            .font(.system(size: 38, weight: .regular))
                            .fontWidth(.expanded)
                            .foregroundColor(appState.theme.textPrimary)
                        
                        Text(isLogin ? "Sign in to continue" : "Get started with Honed")
                            .font(.system(size: 17))
                            .foregroundColor(appState.theme.textMuted)
                    }
                    
                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .font(.system(size: 17))
                            .foregroundColor(appState.theme.textPrimary)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(appState.theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        SecureField("Password", text: $password)
                            .font(.system(size: 17))
                            .foregroundColor(appState.theme.textPrimary)
                            .textContentType(isLogin ? .password : .newPassword)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(appState.theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Primary button
                    Button(action: handleAuth) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 40)
                                .fill(appState.accentColor.swiftUIColor)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text(isLogin ? "Sign In" : "Create Account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .padding(.horizontal, 24)
                    
                    // Toggle auth mode
                    Button(action: { isLogin.toggle() }) {
                        Text(isLogin ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                            .font(.system(size: 15))
                            .foregroundColor(appState.theme.textSecondary)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
        }
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Supabase auth
        // For now, simulate success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            HapticManager.shared.heavy()
            
            // Simulate successful auth
            authState.authStatus = .authenticated(userId: UUID().uuidString)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                authState.nextStep()
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthState())
        .environmentObject(AppState())
}
