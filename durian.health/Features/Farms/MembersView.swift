//
//  MembersView.swift
//  durian.health
//

import SwiftUI

struct MembersView: View {
    let farmId: String
    let isOwner: Bool

    @Environment(FarmStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var members: [Member] {
        store.farm(id: farmId)?.members ?? []
    }

    private var canAdd: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && !isWorking
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Members") {
                    ForEach(members, id: \.email) { member in
                        HStack {
                            Text(member.email)
                            Spacer()
                            Text(member.role == .owner ? "Owner" : "Member")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if isOwner && member.role != .owner {
                                Button("Remove", role: .destructive) { remove(member) }
                            }
                        }
                    }
                }

                if isOwner {
                    Section {
                        TextField("Email of an existing user", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(add)
                        Button("Add Member", action: add)
                            .disabled(!canAdd)
                    } header: {
                        Text("Invite")
                    } footer: {
                        Text("The person must already have a durian.health account.")
                    }
                } else {
                    Section {
                    } footer: {
                        Text("Only the farm owner can add or remove members.")
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func add() {
        guard canAdd else { return }
        run {
            try await store.addMember(farmId: farmId, email: email)
            email = ""
        }
    }

    private func remove(_ member: Member) {
        run { try await store.removeMember(farmId: farmId, email: member.email) }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        isWorking = true
        errorMessage = nil
        Task {
            do { try await work() } catch { errorMessage = error.localizedDescription }
            isWorking = false
        }
    }
}
