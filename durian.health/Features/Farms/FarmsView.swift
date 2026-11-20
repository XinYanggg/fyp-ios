//
//  FarmsView.swift
//  durian.health
//

import SwiftUI

struct FarmRoute: Hashable { let farmId: String }
struct TreeRoute: Hashable { let farmId: String; let treeId: String }

struct FarmsView: View {
    @Environment(FarmStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var showAddFarm = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.farmsPath) {
            content
                .navigationTitle("Farms")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Farm", systemImage: "plus") { showAddFarm = true }
                    }
                }
                .navigationDestination(for: FarmRoute.self) { FarmDetailView(farmId: $0.farmId) }
                .navigationDestination(for: TreeRoute.self) { TreeDetailView(farmId: $0.farmId, treeId: $0.treeId) }
                .sheet(isPresented: $showAddFarm) { AddFarmSheet() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !store.hasLoaded {
            ProgressView().controlSize(.large)
        } else if store.farms.isEmpty {
            if let error = store.loadError {
                ContentUnavailableView {
                    Label("Couldn't load farms", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { Task { await store.load() } }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView {
                    Label("No farms yet", systemImage: "leaf")
                } description: {
                    Text("Add your first farm to start tracking tree health.")
                } actions: {
                    Button("Add Farm") { showAddFarm = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        } else {
            List {
                ForEach(store.farms) { farm in
                    NavigationLink(value: FarmRoute(farmId: farm.id)) {
                        FarmRow(farm: farm)
                    }
                }
            }
            .listRowSpacing(10)
            .refreshable { await store.load() }
            .overlay(alignment: .bottom) {
                if let error = store.loadError {
                    Text(error)
                        .font(.footnote)
                        .padding(10)
                        .background(.regularMaterial, in: Capsule())
                        .padding()
                }
            }
        }
    }
}

private struct FarmRow: View {
    let farm: Farm

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(farm.name).font(.headline)
                    if !farm.location.isEmpty {
                        Text(farm.location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(farm.healthPercent)%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            HealthBar(percent: farm.healthPercent, height: 6)
            HStack(spacing: 14) {
                Label("\(farm.trees.count) trees", systemImage: "tree")
                if farm.attentionCount > 0 {
                    Label("\(farm.attentionCount) need attention", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                Label("\(farm.members.count)", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
