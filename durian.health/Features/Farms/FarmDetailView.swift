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
                summary(farm)
            }

            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { option in
                        Text(label(for: option, in: farm)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                if trees.isEmpty {
                    if farm.trees.isEmpty {
                        Button("Add your first tree", systemImage: "plus") { showAddTree = true }
                    } else {
                        Text("No trees match this filter.").foregroundStyle(.secondary)
                    }
                }
                ForEach(trees) { tree in
                    NavigationLink(value: TreeRoute(farmId: farm.id, treeId: tree.id)) {
                        TreeRow(tree: tree)
                    }
                }
            } header: {
                Text("Trees")
            }
        }
        .navigationTitle(farm.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await store.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Members", systemImage: "person.2") { showMembers = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add Tree", systemImage: "plus") { showAddTree = true }
            }
        }
        .sheet(isPresented: $showAddTree) { AddTreeSheet(farmId: farm.id) }
        .sheet(isPresented: $showMembers) {
            MembersView(farmId: farm.id, isOwner: farm.isOwner(email: auth.user?.email))
        }
    }

    private func summary(_ farm: Farm) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                if !farm.location.isEmpty {
                    Label(farm.location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(farm.healthPercent)% healthy")
                    .font(.subheadline.weight(.semibold))
            }
            HealthBar(percent: farm.healthPercent)
            HStack(spacing: 0) {
                SummaryStat(value: farm.trees.count, label: "Trees")
                SummaryStat(value: farm.healthyCount, label: "Healthy", tint: .durianGreen)
                SummaryStat(value: farm.attentionCount, label: "Attention",
                            tint: farm.attentionCount == 0 ? .secondary : .orange)
            }
        }
        .padding(.vertical, 6)
    }

    private func label(for option: Filter, in farm: Farm) -> String {
        switch option {
        case .all: "All"
        case .healthy: "Healthy (\(farm.healthyCount))"
        case .attention: "Attention (\(farm.attentionCount))"
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
    let value: Int
    let label: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)").font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TreeRow: View {
    let tree: Tree

    var body: some View {
        HStack(spacing: 12) {
            IconTile(
                systemName: "tree.fill",
                color: tree.hasBeenScanned ? Severity(disease: tree.currentDisease).color : .secondary,
                size: 36
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Tree \(tree.id)").font(.headline)
                Text(tree.hasBeenScanned ? "\(tree.cultivar) · \(tree.lastScan)" : "\(tree.cultivar) · Not scanned yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if tree.hasBeenScanned {
                StatusBadge(disease: tree.currentDisease)
            }
        }
        .padding(.vertical, 2)
    }
}
