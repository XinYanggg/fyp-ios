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

nonisolated extension DetectionResult {
    /// "algal_leaf_spot" -> "Algal Leaf Spot", the same formatting the website and Android use.
    var diseaseName: String {
        prediction
            .lowercased()
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// The API returns a 0...1 fraction (e.g. 0.99874). This converts it to a percentage
    /// rounded to 2 decimals (99.87), the same as the website, and clamps it to 0...100.
    var confidencePercent: Double {
        min(max((confidence * 10000).rounded() / 100, 0), 100)
    }

    /// A result that displays as 0% is not a usable diagnosis.
    var isUsable: Bool { confidencePercent.rounded() > 0 }
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
