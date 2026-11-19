//
//  AuthStore.swift
//  durian.health
//

import Foundation
import Observation

/// Owns the signed-in session: login, register, restore on launch, logout.
/// The token and user are kept in the Keychain; the token is also handed to `APIClient`.
@Observable
final class AuthStore {
    private(set) var user: User?
    /// True until the stored session has been checked on launch.
    private(set) var isRestoring = true

    var isSignedIn: Bool { user != nil }

    private let api: APIClient
    private let keychain: KeychainStore
    private let tokenKey = "dh_auth_token"
    private let userKey = "dh_auth_user"

    init(api: APIClient = .shared, keychain: KeychainStore = KeychainStore()) {
        self.api = api
        self.keychain = keychain
        api.onUnauthorized = { [weak self] in
            self?.clearSession()
        }
    }

    // MARK: - Session restore

    /// Loads the stored session. Shows the cached user immediately, then verifies the
    /// token with the backend. Only a 401 signs the user out; network errors keep the session.
    func restoreSession() async {
        guard let token = keychain.read(tokenKey) else {
            isRestoring = false
            return
        }
        api.token = token

        if let json = keychain.read(userKey),
           let cached = try? JSONDecoder().decode(User.self, from: Data(json.utf8)) {
            user = cached
            isRestoring = false
        }

        do {
            let response: MeResponse = try await api.send("/api/mobile/me")
            persist(user: response.user)
            user = response.user
        } catch {
            // 401 is handled by APIClient.onUnauthorized. Other errors keep the cached session.
        }

        // No cached user and the check failed without a 401: we can't show a signed-in UI.
        if user == nil { clearSession() }
        isRestoring = false
    }

    // MARK: - Actions

    func login(email: String, password: String) async throws {
        struct Body: Encodable { let email: String; let password: String }
        let response: AuthResponse = try await api.send(
            "/api/mobile/login",
            method: "POST",
            body: Body(email: Self.normalize(email), password: password)
        )
        try save(token: response.token, user: response.user)
    }

    /// Creates an unverified account. The backend emails a verification link.
    /// Returns the server's confirmation message.
    func register(name: String, email: String, password: String) async throws -> String {
        struct Body: Encodable { let name: String; let email: String; let password: String }
        let response: MessageResponse = try await api.send(
            "/api/register",
            method: "POST",
            body: Body(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: Self.normalize(email),
                password: password
            )
        )
        return response.message
    }

    func logout() {
        clearSession()
    }

    // MARK: - Helpers

    static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func save(token: String, user: User) throws {
        try keychain.save(token, for: tokenKey)
        persist(user: user)
        api.token = token
        self.user = user
    }

    private func persist(user: User) {
        guard let data = try? JSONEncoder().encode(user),
              let json = String(data: data, encoding: .utf8) else { return }
        try? keychain.save(json, for: userKey)
    }

    private func clearSession() {
        keychain.delete(tokenKey)
        keychain.delete(userKey)
        api.token = nil
        user = nil
    }
}
