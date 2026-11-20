//
//  AuthFlowView.swift
//  durian.health
//

import SwiftUI

/// Sign in / create account, presented as a sheet from the welcome screen.
/// The sheet goes away by itself once the user is signed in, because RootView swaps to the tabs.
struct AuthFlowView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case login = "Log In"
        case register = "Create Account"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode
    /// Shown above the login form after a successful registration.
    @State private var notice: String?

    init(initialMode: Mode = .login) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mode == .login ? "Welcome back" : "Create your account")
                            .font(.title.bold())
                        Text(mode == .login
                             ? "Log in to check on your trees."
                             : "Start tracking the health of your durian trees.")
                            .foregroundStyle(.secondary)
                    }

                    Picker("Mode", selection: $mode.animation()) {
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
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark(size: 17) }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: mode) { _, newValue in
            if newValue == .register { notice = nil }
        }
    }
}

#Preview {
    AuthFlowView()
        .environment(AuthStore())
}
