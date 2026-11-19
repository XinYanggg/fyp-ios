//
//  LoginView.swift
//  durian.health
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focused, equals: .email)
                .onSubmit { focused = .password }
                .formField()

            SecureField("Password", text: $password)
                .textContentType(.password)
                .submitLabel(.go)
                .focused($focused, equals: .password)
                .onSubmit(submit)
                .formField()

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Sign In", isLoading: isLoading, action: submit)
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
                try await auth.login(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
