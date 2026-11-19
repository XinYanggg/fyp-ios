//
//  AddTreeSheet.swift
//  durian.health
//

import SwiftUI

struct AddTreeSheet: View {
    let farmId: String

    @Environment(FarmStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var treeId = ""
    @State private var cultivar = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let suggestions = ["Musang King", "D24", "Black Thorn", "D101", "Red Prawn"]

    private var canSave: Bool {
        !treeId.trimmingCharacters(in: .whitespaces).isEmpty
            && !cultivar.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tree ID") {
                    TextField("e.g. A-01", text: $treeId)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Cultivar") {
                    TextField("e.g. Musang King", text: $cultivar)
                        .textInputAutocapitalization(.words)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestions, id: \.self) { name in
                                Button(name) { cultivar = name }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("New Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save", action: save).disabled(!canSave)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await store.addTree(farmId: farmId, treeId: treeId, cultivar: cultivar)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
