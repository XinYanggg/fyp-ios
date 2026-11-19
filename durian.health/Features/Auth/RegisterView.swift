//
//  RegisterView.swift
//  durian.health
//

import SwiftUI

struct RegisterView: View {
    @Environment(AuthStore.self) private var auth

    /// Called with the server's confirmation message after a successful sign-up.
    var onRegistered: (String) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case name, email, password, confirm }

    private static let minPasswordLength = 6

    private var validationMessage: String? {
        if !email.isEmpty, !Self.isValidEmail(email) { return "Enter a valid email address." }
        if !password.isEmpty, password.count < Self.minPasswordLength {
            return "Password must be at least \(Self.minPasswordLength) characters."
        }
        if !confirmPassword.isEmpty, confirmPassword != password { return "Passwords do not match." }
        return nil
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Self.isValidEmail(email)
            && password.count >= Self.minPasswordLength
            && password == confirmPassword
    }

    var body: some View {
        VStack(spacing: 14) {
            TextField("Full name", text: $name)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focused, equals: .name)
                .onSubmit { focused = .email }
                .formField()

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focused, equals: .email)
                .onSubmit { focused = .password }
                .formField()

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .submitLabel(.next)
                .focused($focused, equals: .password)
                .onSubmit { focused = .confirm }
                .formField()

            SecureField("Confirm password", text: $confirmPassword)
                .textContentType(.newPassword)
                .submitLabel(.go)
                .focused($focused, equals: .confirm)
                .onSubmit(submit)
                .formField()

            if let message = errorMessage ?? validationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(errorMessage != nil ? .red : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Create Account", isLoading: isLoading, action: submit)
                .disabled(!canSubmit)
        }
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        focused = nil
        errorMessage = nil
        isLoading = true
        Task {
            do {
                let message = try await auth.register(name: name, email: email, password: password)
                onRegistered(message)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2
            && !parts[0].isEmpty
            && parts[1].contains(".")
            && !parts[1].hasPrefix(".")
            && !parts[1].hasSuffix(".")
    }
}
