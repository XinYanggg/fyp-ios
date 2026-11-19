//
//  ModelExtensions.swift
//  durian.health
//
//  Display helpers for the API models.
//

import Foundation

nonisolated extension Tree {
    var isHealthy: Bool { currentDisease.lowercased() == "healthy" }
    /// True once at least one scan has been saved.
    var hasBeenScanned: Bool { !scans.isEmpty }
}

nonisolated extension Farm {
    var healthyCount: Int { trees.filter(\.isHealthy).count }
    var attentionCount: Int { trees.count - healthyCount }

    /// Share of healthy trees, 0...100. An empty farm counts as fully healthy, as on Android.
    var healthPercent: Int {
        trees.isEmpty ? 100 : Int((Double(healthyCount) / Double(trees.count) * 100).rounded())
    }

    func isOwner(email: String?) -> Bool {
        guard let email else { return false }
        return ownerEmail.lowercased() == email.lowercased()
    }
}

nonisolated enum Severity {
    case healthy, warning, danger

    /// Algal leaf spot is treated as moderate, as on Android. Anything else that isn't healthy is serious.
    init(disease: String) {
        let name = disease.lowercased()
        if name == "healthy" {
            self = .healthy
        } else if name.contains("algal") {
            self = .warning
        } else {
            self = .danger
        }
    }
}

nonisolated extension Double {
    /// Confidence is stored as a percentage (0...100), e.g. 93.25 -> "93.3%".
    var percentText: String {
        "\(formatted(.number.precision(.fractionLength(0...1))))%"
    }
}
