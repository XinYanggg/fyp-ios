//
//  ProfileView.swift
//  durian.health
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(FarmStore.self) private var store
    @State private var confirmSignOut = false

    private var ownedFarms: Int {
        store.farms.filter { $0.isOwner(email: auth.user?.email) }.count
    }

    private var treeCount: Int {
        store.farms.reduce(0) { $0 + $1.trees.count }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                if let user = auth.user {
                    Section {
                        VStack(spacing: 10) {
                            AvatarView(user: user, size: 84)
                            VStack(spacing: 2) {
                                Text(user.name ?? "Farmer").font(.title3.bold())
                                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Your farms") {
                    LabeledContent("Farms", value: "\(store.farms.count)")
                    LabeledContent("Owned by you", value: "\(ownedFarms)")
                    LabeledContent("Trees", value: "\(treeCount)")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Farn Xin Yang · TP074541").font(.subheadline.weight(.semibold))
                        Text("SDG 12: Responsible Consumption and Production")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section {
                    Button("Sign Out", role: .destructive) { confirmSignOut = true }
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Sign out of durian.health?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { auth.logout() }
            }
        }
    }
}
