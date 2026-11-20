//
//  MainTabView.swift
//  durian.health
//

import SwiftUI

/// Signed-in UI. The farm store and router live here so they are discarded on sign-out.
struct MainTabView: View {
    @State private var farmStore = FarmStore()
    @State private var router = AppRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            Tab("Farms", systemImage: "leaf", value: AppTab.farms) {
                FarmsView()
            }
            Tab("Scan", systemImage: "camera.viewfinder", value: AppTab.scan) {
                ScanView()
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView()
            }
        }
        .environment(farmStore)
        .environment(router)
        .task { await farmStore.load() }
    }
}
