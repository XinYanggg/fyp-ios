//
//  Models.swift
//  durian.health
//
//  Codable models matching the fyp-website API (see fyp-website/src/app/lib/type.ts).
//

import Foundation

nonisolated struct User: Codable, Identifiable, Hashable {
    let id: String
    var name: String?
    var email: String
    var image: String?
}

nonisolated struct Member: Codable, Hashable {
    enum Role: String, Codable {
        case owner
        case member
    }

    var email: String
    var role: Role
}

nonisolated struct ScanEntry: Codable, Hashable, Identifiable {
    var id: String { "\(timestamp)|\(disease)" }
    var disease: String
    var confidence: Double
    var timestamp: String
}

nonisolated struct Tree: Codable, Hashable, Identifiable {
    var id: String
    var cultivar: String
    var currentDisease: String
    var confidence: Double
    var lastScan: String
    var scans: [ScanEntry]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        cultivar = try c.decodeIfPresent(String.self, forKey: .cultivar) ?? ""
        currentDisease = try c.decodeIfPresent(String.self, forKey: .currentDisease) ?? "Healthy"
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        lastScan = try c.decodeIfPresent(String.self, forKey: .lastScan) ?? "N/A"
        scans = try c.decodeIfPresent([ScanEntry].self, forKey: .scans) ?? []
    }
}

nonisolated struct Farm: Codable, Hashable, Identifiable {
    /// MongoDB ObjectId as a hex string.
    var id: String
    var ownerEmail: String
    var name: String
    var location: String
    var members: [Member]
    var trees: [Tree]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ownerEmail, name, location, members, trees
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ownerEmail = try c.decode(String.self, forKey: .ownerEmail)
        name = try c.decode(String.self, forKey: .name)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        members = try c.decodeIfPresent([Member].self, forKey: .members) ?? []
        trees = try c.decodeIfPresent([Tree].self, forKey: .trees) ?? []
    }
}

// MARK: - Response envelopes

nonisolated struct AuthResponse: Decodable {
    let token: String
    let user: User
}

nonisolated struct MeResponse: Decodable {
    let user: User
}

nonisolated struct MessageResponse: Decodable {
    let message: String
}

nonisolated struct FarmsResponse: Decodable {
    let farms: [Farm]
}

nonisolated struct FarmResponse: Decodable {
    let farm: Farm
}

nonisolated struct DetectionResult: Decodable, Hashable {
    let prediction: String
    let confidence: Double
}
