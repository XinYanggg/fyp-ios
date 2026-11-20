//
//  HomeView.swift
//  durian.health
//

import SwiftUI

/// Dashboard: health of one farm, a scan shortcut and the trees that need attention.
struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(FarmStore.self) private var store
    @Environment(AppRouter.self) private var router

    /// Farm shown in the overview. Falls back to the first farm.
    @State private var selectedFarmId: String?

    private var farm: Farm? {
        selectedFarmId.flatMap { store.farm(id: $0) } ?? store.farms.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !store.hasLoaded {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let farm {
                        overview(farm)
                        scanShortcut
                        attention(farm)
                    } else if let error = store.loadError {
                        ContentUnavailableView {
                            Label("Couldn't load farms", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("Try Again") { Task { await store.load() } }
                        }
                        .card()
                    } else {
                        emptyState
                    }
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable { await store.load() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Wordmark(size: 26)
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let user = auth.user {
                Button {
                    router.selectedTab = .profile
                } label: {
                    AvatarView(user: user, size: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile")
            }
        }
    }

    private func overview(_ farm: Farm) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    farmPicker(current: farm)
                    if !farm.location.isEmpty {
                        Label(farm.location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(farm.healthPercent)%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("healthy").font(.caption).foregroundStyle(.secondary)
                }
            }

            HealthBar(percent: farm.healthPercent)

            HStack {
                stat("\(farm.trees.count)", "Trees")
                stat("\(farm.healthyCount)", "Healthy")
                stat("\(farm.attentionCount)", "Attention")
                Spacer()
                Button {
                    router.openFarm(farm.id)
                } label: {
                    HStack(spacing: 2) {
                        Text("View farm")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .card(padding: 20)
    }

    @ViewBuilder
    private func farmPicker(current: Farm) -> some View {
        if store.farms.count > 1 {
            Menu {
                Picker("Farm", selection: Binding(
                    get: { current.id },
                    set: { selectedFarmId = $0 }
                )) {
                    ForEach(store.farms) { Text($0.name).tag($0.id) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(current.name).font(.title3.bold())
                    Image(systemName: "chevron.up.chevron.down").font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
        } else {
            Text(current.name).font(.title3.bold())
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.trailing, 16)
    }

    private var scanShortcut: some View {
        Button {
            router.scan()
        } label: {
            HStack(spacing: 14) {
                IconTile(systemName: "camera.viewfinder", size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan a leaf").font(.headline).foregroundStyle(.primary)
                    Text("Check for leaf spot, algal disease and blight.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func attention(_ farm: Farm) -> some View {
        let trees = farm.trees.filter { !$0.isHealthy }
        VStack(alignment: .leading, spacing: 10) {
            Text("Needs attention").font(.title3.bold())
            if trees.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Color.durianGreen)
                    Text(farm.trees.isEmpty
                         ? "Add trees to this farm to start tracking their health."
                         : "All trees on this farm look healthy.")
                        .foregroundStyle(.secondary)
                }
                .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(trees.enumerated()), id: \.element.id) { index, tree in
                        Button {
                            router.openFarm(farm.id)
                            router.farmsPath.append(TreeRoute(farmId: farm.id, treeId: tree.id))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tree \(tree.id)").font(.headline).foregroundStyle(.primary)
                                    Text(tree.cultivar).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(disease: tree.currentDisease)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < trees.count - 1 { Divider() }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            IconTile(systemName: "leaf.fill", size: 56)
            Text("No farms yet").font(.title3.bold())
            Text("Create your first farm to register trees and start scanning leaves.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Go to Farms") { router.selectedTab = .farms }
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .card(padding: 24)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = switch hour {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
        if let first = auth.user?.name?.split(separator: " ").first {
            return "\(part), \(first)"
        }
        return part
    }
}
