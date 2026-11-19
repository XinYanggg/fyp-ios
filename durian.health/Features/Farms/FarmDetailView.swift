//
//  FarmDetailView.swift
//  durian.health
//

import SwiftUI

struct FarmDetailView: View {
    let farmId: String

    @Environment(FarmStore.self) private var store
    @Environment(AuthStore.self) private var auth

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case healthy = "Healthy"
        case attention = "Attention"
        var id: String { rawValue }
    }

    @State private var filter: Filter = .all
    @State private var showAddTree = false
    @State private var showMembers = false

    var body: some View {
        if let farm = store.farm(id: farmId) {
            content(for: farm)
        } else {
            ContentUnavailableView("Farm not found", systemImage: "leaf")
        }
    }

    private func content(for farm: Farm) -> some View {
        let trees = filteredTrees(in: farm)
        return List {
            Section {
                HStack {
                    SummaryStat(value: "\(farm.trees.count)", label: "Trees")
                    Divider()
                    SummaryStat(value: "\(farm.healthPercent)%", label: "Healthy", tint: .durianGreen)
                    Divider()
                    SummaryStat(value: "\(farm.attentionCount)", label: "Attention", tint: farm.attentionCount == 0 ? .secondary : .orange)
                }
                if !farm.location.isEmpty {
                    Label(farm.location, systemImage: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Trees") {
                if trees.isEmpty {
                    Text(farm.trees.isEmpty ? "No trees yet. Tap + to add one." : "No trees match this filter.")
                        .foregroundStyle(.secondary)
                }
                ForEach(trees) { tree in
                    NavigationLink(value: TreeRoute(farmId: farm.id, treeId: tree.id)) {
                        TreeRow(tree: tree)
                    }
                }
            }
        }
        .navigationTitle(farm.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await store.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Add Tree", systemImage: "plus") { showAddTree = true }
                    Button("Members", systemImage: "person.2") { showMembers = true }
                }
            }
        }
        .sheet(isPresented: $showAddTree) { AddTreeSheet(farmId: farm.id) }
        .sheet(isPresented: $showMembers) {
            MembersView(farmId: farm.id, isOwner: farm.isOwner(email: auth.user?.email))
        }
    }

    private func filteredTrees(in farm: Farm) -> [Tree] {
        switch filter {
        case .all: farm.trees
        case .healthy: farm.trees.filter(\.isHealthy)
        case .attention: farm.trees.filter { !$0.isHealthy }
        }
    }
}

private struct SummaryStat: View {
    let value: String
    let label: String
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TreeRow: View {
    let tree: Tree

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tree \(tree.id)").font(.headline)
                Spacer()
                Text(tree.cultivar).font(.subheadline).foregroundStyle(.secondary)
            }
            if tree.hasBeenScanned {
                StatusBadge(disease: tree.currentDisease, confidence: tree.confidence)
                Text("Last scan: \(tree.lastScan)").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Not scanned yet").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
