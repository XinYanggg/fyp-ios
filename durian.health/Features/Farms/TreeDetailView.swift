//
//  TreeDetailView.swift
//  durian.health
//

import SwiftUI

struct TreeDetailView: View {
    let farmId: String
    let treeId: String

    @Environment(FarmStore.self) private var store

    private var tree: Tree? {
        store.farm(id: farmId)?.trees.first { $0.id == treeId }
    }

    var body: some View {
        if let tree {
            List {
                Section("Current status") {
                    LabeledContent("Cultivar", value: tree.cultivar)
                    if tree.hasBeenScanned {
                        LabeledContent("Condition") {
                            StatusBadge(disease: tree.currentDisease, confidence: tree.confidence)
                        }
                        LabeledContent("Last scan", value: tree.lastScan)
                    } else {
                        Text("Not scanned yet").foregroundStyle(.secondary)
                    }
                }

                Section("Scan history") {
                    if tree.scans.isEmpty {
                        Text("No scans recorded.").foregroundStyle(.secondary)
                    }
                    // The backend appends new scans, so show newest first.
                    ForEach(Array(tree.scans.reversed().enumerated()), id: \.offset) { _, scan in
                        VStack(alignment: .leading, spacing: 6) {
                            StatusBadge(disease: scan.disease, confidence: scan.confidence)
                            Text(scan.timestamp).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Tree \(tree.id)")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await store.load() }
        } else {
            ContentUnavailableView("Tree not found", systemImage: "tree")
        }
    }
}
