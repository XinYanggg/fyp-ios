//
//  RootView.swift
//  durian.health
//

import SwiftUI

/// Chooses between the launch spinner, the auth screens and the signed-in UI.
struct RootView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        Group {
            if auth.isRestoring {
                ProgressView()
                    .controlSize(.large)
            } else if auth.isSignedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
        .animation(.default, value: auth.isRestoring)
        .animation(.default, value: auth.isSignedIn)
        .task { await auth.restoreSession() }
    }
}

#Preview {
    RootView()
        .environment(AuthStore())
}
