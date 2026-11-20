//
//  StatusBadge.swift
//  durian.health
//

import SwiftUI

/// Pill showing a disease name (and optional confidence) in a severity color.
///
/// Built from an HStack rather than `Label`, so List rows don't apply their own
/// label styling to it. It always takes its natural size.
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
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(confidence.map { "\(disease) (\($0.percentText))" } ?? disease)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}

/// List row with a title on the left and a status badge on the right.
struct StatusRow: View {
    let title: String
    let disease: String
    var confidence: Double?

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            StatusBadge(disease: disease, confidence: confidence)
        }
    }
}

#Preview {
    List {
        StatusRow(title: "Condition", disease: "Healthy")
        StatusRow(title: "Condition", disease: "Algal Leaf Spot", confidence: 91.2)
        StatusBadge(disease: "Leaf Blight", confidence: 78)
    }
}
