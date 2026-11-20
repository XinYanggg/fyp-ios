//
//  GoogleSignInSection.swift
//  durian.health
//

import GoogleSignInSwift
import SwiftUI
import UIKit

/// "or" divider plus Google's branded sign-in button. Hidden when the Google client IDs
/// aren't configured in Secrets.xcconfig.
struct GoogleSignInSection: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        if AppConfig.isGoogleSignInConfigured {
            VStack(spacing: 14) {
                HStack {
                    line
                    Text("or").font(.footnote).foregroundStyle(.secondary)
                    line
                }

                ZStack {
                    GoogleSignInButton(
                        scheme: colorScheme == .dark ? .dark : .light,
                        style: .wide,
                        action: signIn
                    )
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.4 : 1)
                    if isLoading { ProgressView() }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var line: some View {
        Rectangle().fill(.separator).frame(height: 1)
    }

    private func signIn() {
        guard !isLoading, let presenter = UIApplication.shared.topViewController else {
            errorMessage = "Couldn't start Google Sign-In. Please try again."
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await auth.loginWithGoogle(presenting: presenter)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private extension UIApplication {
    /// The frontmost view controller in the active window, used to present Google's sign-in sheet.
    var topViewController: UIViewController? {
        let window = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
