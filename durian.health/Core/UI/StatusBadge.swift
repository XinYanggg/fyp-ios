//
//  StatusBadge.swift
//  durian.health
//

import SwiftUI

/// Pill showing a disease name (and optional confidence) in a severity color.
struct StatusBadge: View {
    let disease: String
    var confidence: Double?

    private var severity: Severity { Severity(disease: disease) }

    private var color: Color {
        switch severity {
        case .healthy: .durianGreen
        case .warning: .orange
        case .danger: .red
        }
    }

    private var icon: String {
        switch severity {
        case .healthy: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "exclamationmark.octagon.fill"
        }
    }

    var body: some View {
        Label {
            Text(confidence.map { "\(disease) (\($0.percentText))" } ?? disease)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        StatusBadge(disease: "Healthy")
        StatusBadge(disease: "Algal Leaf Spot", confidence: 91.2)
        StatusBadge(disease: "Leaf Blight", confidence: 78)
    }
    .padding()
}
