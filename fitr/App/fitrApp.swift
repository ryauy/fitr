//
//  fitrApp.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import Firebase
import Auth0

@main
struct fitrApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                DashboardView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
