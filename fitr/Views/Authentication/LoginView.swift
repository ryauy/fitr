//
//  LoginView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [AppColors.peachSnaps, AppColors.lightPink.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and app name
                VStack(spacing: 10) {
                    Image(systemName: "tshirt.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppColors.davyGrey)
                    
                    Text("fitr")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.davyGrey)
                    
                    Text("Your AI Wardrobe Assistant")
                        .font(.subheadline)
                        .foregroundColor(AppColors.davyGrey.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                // Login/Signup form
                VStack(spacing: 20) {
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.davyGrey))
                    } else {
                        Button(action: {
                            if isSignUp {
                                authManager.signUp(email: email, password: password, name: name)
                            } else {
                                authManager.loginWithEmailPassword(email: email, password: password)
                            }
                        }) {
                            Text(isSignUp ? "Sign Up" : "Login")
                                .frame(maxWidth: .infinity)
                        }
                        .primaryButtonStyle()
                    }
                    
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(AppColors.davyGrey)
                    }
                }
                .padding(.horizontal, 30)
                
                // Social login options
                VStack(spacing: 15) {
                    Text("Or continue with")
                        .font(.footnote)
                        .foregroundColor(AppColors.davyGrey)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            authManager.loginWithAuth0()
                        }) {
                            SocialLoginButton(image: "g.circle.fill", text: "Google")
                        }
                        
                        Button(action: {
                            authManager.loginWithApple()
                        }) {
                            SocialLoginButton(image: "apple.logo", text: "Apple")
                        }
                    }
                }
                .padding(.top, 10)
                
                if let error = authManager.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 50)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.moonMist.opacity(0.3))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct SocialLoginButton: View {
    let image: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 25)
        .background(AppColors.moonMist.opacity(0.5))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
