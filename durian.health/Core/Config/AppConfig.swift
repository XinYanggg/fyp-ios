//
//  AppConfig.swift
//  durian.health
//

import Foundation

nonisolated enum AppConfig {
    /// Debug builds talk to the local Next.js server by default.
    private static let debugDefault = "http://localhost:3000"

    /// Backend base URL (no trailing slash).
    ///
    /// - Debug: `APIBaseURLDebug` from Info.plist if set, otherwise `http://localhost:3000`.
    /// - Release: `APIBaseURL` from Info.plist (filled from `API_BASE_URL` in Secrets.xcconfig).
    static var apiBaseURL: URL {
        #if DEBUG
        let raw = plistValue("APIBaseURLDebug") ?? debugDefault
        #else
        guard let raw = plistValue("APIBaseURL") else {
            preconditionFailure("APIBaseURL is missing. Set API_BASE_URL in Config/Secrets.xcconfig and add the APIBaseURL key to Info.plist.")
        }
        #endif
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        guard let url = URL(string: trimmed) else {
            preconditionFailure("Invalid API base URL: \(raw)")
        }
        return url
    }

    /// True when both Google client IDs are filled in (GIDClientID and GIDServerClientID in
    /// Info.plist, from Secrets.xcconfig). The Google button is hidden otherwise, because
    /// GoogleSignIn throws on an invalid client ID.
    static var isGoogleSignInConfigured: Bool {
        let suffix = ".apps.googleusercontent.com"
        return ["GIDClientID", "GIDServerClientID"].allSatisfy { key in
            guard let value = plistValue(key) else { return false }
            return value.hasSuffix(suffix) && value.count > suffix.count && !value.hasPrefix(".")
        }
    }

    /// Reads a string from Info.plist. Returns nil when missing, empty, or an
    /// unexpanded `$(VARIABLE)` placeholder.
    private static func plistValue(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }
}
