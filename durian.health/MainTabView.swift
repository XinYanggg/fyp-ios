//
//  MainTabView.swift
//  durian.health
//

import SwiftUI

/// Signed-in UI. The farm store lives here so it is discarded on sign-out.
struct MainTabView: View {
    @State private var farmStore = FarmStore()

    var body: some View {
        TabView {
            Tab("Farms", systemImage: "leaf") {
                FarmsView()
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView()
            }
        }
        .environment(farmStore)
    }
}
