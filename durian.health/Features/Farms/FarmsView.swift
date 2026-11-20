//
//  FarmsView.swift
//  durian.health
//

import SwiftUI

struct FarmRoute: Hashable { let farmId: String }
struct TreeRoute: Hashable { let farmId: String; let treeId: String }

struct FarmsView: View {
    @Environment(FarmStore.self) private var store
    @State private var showAddFarm = false

    var body: some View {
        NavigationStack {
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
            List(store.farms) { farm in
                NavigationLink(value: FarmRoute(farmId: farm.id)) {
                    FarmRow(farm: farm)
                }
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text(farm.name).font(.headline)
            if !farm.location.isEmpty {
                Label(farm.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(farm.trees.count) trees", systemImage: "tree")
                Label("\(farm.healthPercent)% healthy", systemImage: "heart.fill")
                    .foregroundStyle(farm.attentionCount == 0 ? Color.durianGreen : .orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
