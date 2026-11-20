//
//  AuthFlowView.swift
//  durian.health
//

import SwiftUI

/// Sign in / create account screen shown while signed out.
struct AuthFlowView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case login = "Sign In"
        case register = "Create Account"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .login
    /// Shown above the login form after a successful registration.
    @State private var notice: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if let notice {
                    Label(notice, systemImage: "envelope.badge")
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.durianGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                switch mode {
                case .login:
                    LoginView()
                case .register:
                    RegisterView { message in
                        notice = message
                        mode = .login
                    }
                }

                // Google creates the account on first sign-in, so it fits both modes.
                GoogleSignInSection()
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: mode) { _, newValue in
            if newValue == .register { notice = nil }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.durianGreen)
            Text("durian.health")
                .font(.largeTitle.bold())
            Text("Monitor your durian trees and catch leaf disease early.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }
}

#Preview {
    AuthFlowView()
        .environment(AuthStore())
}
