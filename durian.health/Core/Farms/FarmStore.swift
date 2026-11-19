//
//  FarmStore.swift
//  durian.health
//

import Foundation
import Observation

/// Holds the signed-in user's farms and wraps the farm endpoints.
/// Every mutating endpoint returns the updated farm, which replaces the local copy.
@Observable
final class FarmStore {
    private(set) var farms: [Farm] = []
    private(set) var isLoading = false
    /// True after the first load attempt finishes, so the UI can tell "empty" from "not loaded yet".
    private(set) var hasLoaded = false
    private(set) var loadError: String?

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func farm(id: String) -> Farm? {
        farms.first { $0.id == id }
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        loadError = nil
        do {
            let response: FarmsResponse = try await api.send("/api/farm/get")
            farms = response.farms
        } catch is CancellationError {
            // Pull-to-refresh was cancelled; keep what we have.
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
        hasLoaded = true
    }

    // MARK: - Mutations

    @discardableResult
    func addFarm(name: String, location: String) async throws -> Farm {
        struct Body: Encodable { let name: String; let location: String }
        let response: FarmResponse = try await api.send(
            "/api/farm/add",
            method: "POST",
            body: Body(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        farms.append(response.farm)
        return response.farm
    }

    func addTree(farmId: String, treeId: String, cultivar: String) async throws {
        struct Body: Encodable { let farmId: String; let treeId: String; let cultivar: String }
        let response: FarmResponse = try await api.send(
            "/api/farm/tree/add",
            method: "POST",
            body: Body(
                farmId: farmId,
                treeId: treeId.trimmingCharacters(in: .whitespacesAndNewlines),
                cultivar: cultivar.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        replace(response.farm)
    }

    func addMember(farmId: String, email: String) async throws {
        try await updateMember(path: "/api/farm/member/add", farmId: farmId, email: email)
    }

    func removeMember(farmId: String, email: String) async throws {
        try await updateMember(path: "/api/farm/member/remove", farmId: farmId, email: email)
    }

    /// Replaces a farm after another endpoint (such as saving a scan) returned its new state.
    func replace(_ farm: Farm) {
        if let index = farms.firstIndex(where: { $0.id == farm.id }) {
            farms[index] = farm
        } else {
            farms.append(farm)
        }
    }

    private func updateMember(path: String, farmId: String, email: String) async throws {
        struct Body: Encodable { let farmId: String; let email: String }
        let response: FarmResponse = try await api.send(
            path,
            method: "POST",
            body: Body(farmId: farmId, email: AuthStore.normalize(email))
        )
        replace(response.farm)
    }
}
