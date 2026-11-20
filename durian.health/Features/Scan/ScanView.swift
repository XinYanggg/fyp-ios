//
//  ScanView.swift
//  durian.health
//

import PhotosUI
import SwiftUI

struct ScanView: View {
    @Environment(FarmStore.self) private var store

    // Target
    @State private var farmId: String?
    @State private var treeId: String?

    // Photo
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var photo: Data?          // prepared JPEG, uploaded as-is
    @State private var preview: UIImage?

    // Progress
    @State private var result: DetectionResult?
    @State private var isAnalyzing = false
    @State private var isSaving = false
    @State private var isSaved = false
    @State private var errorMessage: String?

    private var farm: Farm? { farmId.flatMap { store.farm(id: $0) } }
    private var tree: Tree? { treeId.flatMap { id in farm?.trees.first { $0.id == id } } }

    var body: some View {
        NavigationStack {
            Group {
                if !store.hasLoaded {
                    ProgressView().controlSize(.large)
                } else if store.farms.isEmpty {
                    ContentUnavailableView(
                        "No farms yet",
                        systemImage: "leaf",
                        description: Text("Add a farm and a tree in the Farms tab, then come back to scan a leaf.")
                    )
                } else {
                    form
                }
            }
            .navigationTitle("Scan")
        }
        .onAppear(perform: ensureSelection)
        .onChange(of: store.farms) { ensureSelection() }
        .onChange(of: farmId) { ensureSelection() }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(from: item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in Task { await prepare(data) } }
                .ignoresSafeArea()
        }
    }

    // MARK: - Form

    private var form: some View {
        Form {
            Section {
                photoArea
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                if CameraPicker.isAvailable {
                    Button("Take Photo", systemImage: "camera") { showCamera = true }
                }
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            } header: {
                Text("Leaf photo")
            } footer: {
                Text("Photograph a single leaf in good light, filling most of the frame.")
            }

            Section {
                PrimaryButton(title: "Analyze Leaf", isLoading: isAnalyzing, action: analyze)
                    .disabled(photo == nil || isSaving)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if let result {
                resultSection(result)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
    }

    private var photoArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.fill.tertiary)
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder").font(.system(size: 40))
                    Text("No photo selected").font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func resultSection(_ result: DetectionResult) -> some View {
        Section("Diagnosis") {
            LabeledContent("Condition") {
                StatusBadge(disease: result.diseaseName, confidence: result.confidencePercent)
            }

            if isSaved {
                Label("Saved to tree \(tree?.id ?? "")", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.durianGreen)
                Button("Scan Another Leaf", action: reset)
            }
        }

        if !result.isUsable {
            Section {
                Label("The model returned 0% confidence. Retake a clearer photo of the leaf.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        } else if !isSaved {
            Section("Save result to") {
                Picker("Farm", selection: $farmId) {
                    ForEach(store.farms) { Text($0.name).tag(Optional($0.id)) }
                }
                if let farm, !farm.trees.isEmpty {
                    Picker("Tree", selection: $treeId) {
                        ForEach(farm.trees) { Text("\($0.id) · \($0.cultivar)").tag(Optional($0.id)) }
                    }
                } else {
                    Text("This farm has no trees. Add one in the Farms tab.")
                        .foregroundStyle(.secondary)
                }
                Button(action: save) {
                    if isSaving {
                        HStack { ProgressView(); Text("Saving…") }
                    } else {
                        Text(tree.map { "Save to Tree \($0.id)" } ?? "Save Result")
                    }
                }
                .disabled(tree == nil || isSaving)
            }
        }
    }

    // MARK: - Actions

    /// Keeps the farm/tree pickers pointing at something that exists.
    private func ensureSelection() {
        guard !store.farms.isEmpty else { return }
        if farm == nil { farmId = store.farms.first?.id }
        if tree == nil { treeId = farm?.trees.first?.id }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "Couldn't read that photo. Try another one."
            return
        }
        await prepare(data)
    }

    private func prepare(_ data: Data) async {
        guard let jpeg = await Task.detached(operation: { ImagePreparer.jpegData(from: data) }).value,
              let image = UIImage(data: jpeg) else {
            errorMessage = "Couldn't process that photo. Try another one."
            return
        }
        photo = jpeg
        preview = image
        result = nil
        isSaved = false
        errorMessage = nil
    }

    private func analyze() {
        guard let photo, !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        result = nil
        isSaved = false
        Task {
            do {
                let detection: DetectionResult = try await APIClient.shared.upload(
                    "/api/scan/detect",
                    fieldName: "file",
                    fileName: "leaf.jpg",
                    mimeType: "image/jpeg",
                    data: photo
                )
                result = detection
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    private func save() {
        guard let result, result.isUsable, let farmId, let treeId, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await store.saveScan(
                    farmId: farmId,
                    treeId: treeId,
                    disease: result.diseaseName,
                    confidence: result.confidencePercent
                )
                isSaved = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func reset() {
        photo = nil
        preview = nil
        result = nil
        isSaved = false
        errorMessage = nil
    }
}
