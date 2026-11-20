//
//  ProfileView.swift
//  durian.health
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            List {
                if let user = auth.user {
                    Section {
                        HStack(spacing: 14) {
                            AvatarView(user: user, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name ?? "Farmer").font(.headline)
                                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) { confirmSignOut = true }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Sign out of durian.health?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { auth.logout() }
            }
        }
    }
}
