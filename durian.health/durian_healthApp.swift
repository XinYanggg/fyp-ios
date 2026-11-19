//
//  durian_healthApp.swift
//  durian.health
//
//  Created by Farn Xin Yang on 18/11/2026.
//

import SwiftUI

@main
struct durian_healthApp: App {
    @State private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .tint(.durianGreen)
        }
    }
}
