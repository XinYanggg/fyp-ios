//
//  AppRouter.swift
//  durian.health
//

import Observation
import SwiftUI

enum AppTab: Hashable {
    case home, farms, scan, profile
}

/// Cross-tab navigation for the signed-in UI, e.g. "Scan This Tree" from a tree page.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    /// Navigation stack of the Farms tab.
    var farmsPath = NavigationPath()
    /// Farm and tree to preselect the next time the Scan tab appears. Cleared once applied.
    var scanTarget: TreeRoute?

    func openFarm(_ farmId: String) {
        var path = NavigationPath()
        path.append(FarmRoute(farmId: farmId))
        farmsPath = path
        selectedTab = .farms
    }

    func scan(farmId: String? = nil, treeId: String? = nil) {
        if let farmId, let treeId {
            scanTarget = TreeRoute(farmId: farmId, treeId: treeId)
        }
        selectedTab = .scan
    }
}
