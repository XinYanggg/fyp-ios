//
//  SignedInPlaceholderView.swift
//  durian.health
//
//  Temporary screen shown after sign-in. Replaced by the farms UI in step 3.
//

import SwiftUI

struct SignedInPlaceholderView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.durianGreen)
                Text("Signed in")
                    .font(.title2.bold())
                if let user = auth.user {
                    VStack(spacing: 4) {
                        if let name = user.name { Text(name).font(.headline) }
                        Text(user.email).foregroundStyle(.secondary)
                    }
                }
                Button("Sign Out", role: .destructive) { auth.logout() }
                    .buttonStyle(.bordered)
            }
            .navigationTitle("durian.health")
        }
    }
}
