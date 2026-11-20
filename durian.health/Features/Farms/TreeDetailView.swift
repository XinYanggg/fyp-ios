//
//  TreeDetailView.swift
//  durian.health
//

import SwiftUI

struct TreeDetailView: View {
    let farmId: String
    let treeId: String

    @Environment(FarmStore.self) private var store
    @Environment(AppRouter.self) private var router

    private var tree: Tree? {
        store.farm(id: farmId)?.trees.first { $0.id == treeId }
    }

    var body: some View {
        if let tree {
            List {
                Section {
                    header(tree)
                }

                Section {
                    PrimaryButton(title: "Scan This Tree", systemImage: "camera.viewfinder") {
                        router.scan(farmId: farmId, treeId: treeId)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Scan history") {
                    if tree.scans.isEmpty {
                        Text("No scans recorded yet.").foregroundStyle(.secondary)
                    }
                    // The backend appends new scans, so show newest first.
                    ForEach(Array(tree.scans.reversed().enumerated()), id: \.offset) { _, scan in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Severity(disease: scan.disease).color)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scan.disease).font(.subheadline.weight(.semibold))
                                Text(scan.timestamp).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(scan.confidence.percentText)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
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

    private func header(_ tree: Tree) -> some View {
        HStack(spacing: 14) {
            IconTile(
                systemName: "tree.fill",
                color: tree.hasBeenScanned ? Severity(disease: tree.currentDisease).color : .secondary,
                size: 52
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(tree.cultivar).font(.headline)
                if tree.hasBeenScanned {
                    StatusBadge(disease: tree.currentDisease, confidence: tree.confidence)
                    Text("Last scan: \(tree.lastScan)").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Not scanned yet").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}
