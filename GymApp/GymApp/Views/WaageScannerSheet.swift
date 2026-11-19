import SwiftUI
import Vision
import PhotosUI

public struct WaageScannerSheet: View {
    public var targetDate: Date
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var currentWeightKg: Double
    @State private var isAnalyzing: Bool = false
    @State private var recognitionStatusText: String? = nil
    @State private var showingImagePicker: Bool = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var manualText: String = ""
    @State private var isManualInputActive: Bool = false

    public init(targetDate: Date = Date()) {
        self.targetDate = targetDate
        let initialWeight = GymStore.shared.measurements.first(where: {
            $0.type == .weight && Calendar.current.isDate($0.date, inSameDayAs: targetDate)
        })?.value ?? GymStore.shared.latestMeasurement(for: .weight)?.value ?? 80.0
        self._currentWeightKg = State(initialValue: initialWeight)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MORGEN-ROUTINE • WAAGE-SCANNER")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.0)
                                .foregroundColor(GymTheme.cyanAccent)

                            Text("Körpergewicht erfassen")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(GymTheme.textPrimary)

                            Text("Fotografiere das Display deiner Waage. Die integrierte OCR-Texterkennung extrahiert die Kilogramm-Zahl automatisch.")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.textSecondary)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))

                        // Digital Weight Readout Display
                        VStack(spacing: 8) {
                            Text("GEMESSENES GEWICHT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.0)
                                .foregroundColor(GymTheme.textMuted)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(String(format: "%.1f", currentWeightKg).replacingOccurrences(of: ".", with: ","))
                                    .font(.system(size: 48, weight: .black, design: .monospaced))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("kg")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(GymTheme.cyanAccent)
                            }

                            if let status = recognitionStatusText {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(GymTheme.sageGreen)
                                    Text(status)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(GymTheme.sageGreen)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(GymTheme.sageGreen.opacity(0.15))
                                .cornerRadius(6)
                            }

                            // Fine Adjustment Steppers
                            HStack(spacing: 8) {
                                adjustButton(label: "-1.0", delta: -1.0)
                                adjustButton(label: "-0.1", delta: -0.1)
                                adjustButton(label: "+0.1", delta: 0.1)
                                adjustButton(label: "+1.0", delta: 1.0)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(Color(red: 0.08, green: 0.09, blue: 0.12))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GymTheme.cyanAccent.opacity(0.3), lineWidth: 1.2))

                        // Camera & Gallery Scanning Actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WAAGE SCANNEN")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.0)
                                .foregroundColor(GymTheme.textMuted)

                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button {
                                    imagePickerSourceType = .camera
                                    showingImagePicker = true
                                    HapticFeedback.light()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(GymTheme.bg)
                                        Text("Waage mit Kamera fotografieren")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(GymTheme.bg)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(GymTheme.bg)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(GymTheme.cyanAccent)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }

                            // PhotosPicker Fallback
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 14))
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("Aus Foto-Mediathek waehlen")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(GymTheme.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                guard let item = newItem else { return }
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        analyzeImageWithVision(image: image)
                                    }
                                }
                            }
                        }

                        // Manual Entry Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isManualInputActive.toggle()
                                    if isManualInputActive {
                                        manualText = String(format: "%.1f", currentWeightKg)
                                    }
                                }
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isManualInputActive ? "keyboard.chevron.compact.down" : "square.and.pencil")
                                        .font(.system(size: 11))
                                    Text(isManualInputActive ? "Zifferneingabe schliessen" : "Gewicht manuell eintippen")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Image(systemName: isManualInputActive ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            if isManualInputActive {
                                HStack(spacing: 8) {
                                    TextField("z. B. 84.5", text: $manualText)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(GymTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))

                                    Button("Uebernehmen") {
                                        let sanitized = manualText.replacingOccurrences(of: ",", with: ".")
                                        if let val = Double(sanitized), val >= 30.0 && val <= 300.0 {
                                            currentWeightKg = val
                                            recognitionStatusText = "Manuell eingetragen: \(String(format: "%.1f", val)) kg"
                                            isManualInputActive = false
                                            hideKeyboard()
                                            HapticFeedback.success()
                                        }
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(GymTheme.strongBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                        }

                        Spacer(minLength: 20)

                        // Save Action Button
                        Button {
                            saveWeight()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Gewicht speichern (\(String(format: "%.1f", currentWeightKg).replacingOccurrences(of: ".", with: ",")) kg)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.finishGreen)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Waage erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $showingImagePicker) {
                WaageImagePicker(sourceType: imagePickerSourceType) { pickedImage in
                    showingImagePicker = false
                    analyzeImageWithVision(image: pickedImage)
                }
            }
        }
    }

    private func adjustButton(label: String, delta: Double) -> some View {
        Button {
            let next = max(30.0, min(250.0, currentWeightKg + delta))
            currentWeightKg = (next * 10).rounded() / 10
            HapticFeedback.light()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func saveWeight() {
        let rounded = (currentWeightKg * 10).rounded() / 10
        store.addMeasurement(type: .weight, value: rounded, date: targetDate, note: "Waage-Scan")
        HapticFeedback.success()
        dismiss()
    }

    // MARK: - Vision OCR Analyzer
    private func analyzeImageWithVision(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        isAnalyzing = true

        let request = VNRecognizeTextRequest { req, error in
            defer {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                }
            }
            guard error == nil, let observations = req.results as? [VNRecognizedTextObservation] else {
                return
            }

            var detectedNumbers: [Double] = []

            for obs in observations {
                guard let topCandidate = obs.topCandidates(1).first else { continue }
                let text = topCandidate.string

                // Regex matches patterns like "84.2", "84,2", "84.2kg", "84.2 kg"
                let matches = extractWeightCandidates(from: text)
                detectedNumbers.append(contentsOf: matches)
            }

            DispatchQueue.main.async {
                if let best = detectedNumbers.first {
                    self.currentWeightKg = best
                    self.recognitionStatusText = "OCR-Erkannt: \(String(format: "%.1f", best).replacingOccurrences(of: ".", with: ",")) kg"
                    HapticFeedback.success()
                } else {
                    self.recognitionStatusText = "Keine Zahl erkannt • Bitte manuell anpassen"
                    HapticFeedback.warning()
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func extractWeightCandidates(from text: String) -> [Double] {
        var results: [Double] = []
        let sanitized = text.replacingOccurrences(of: ",", with: ".")

        // Regex for numbers with 1 or 2 decimal places: e.g. 78.5 or 84.2
        let pattern = #"\b([3-9]\d(?:\.\d{1,2})?|[1-2]\d{2}(?:\.\d{1,2})?)\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = sanitized as NSString
            let matches = regex.matches(in: sanitized, options: [], range: NSRange(location: 0, length: nsString.length))
            for m in matches {
                let str = nsString.substring(with: m.range)
                if let val = Double(str), val >= 35.0 && val <= 250.0 {
                    results.append(val)
                }
            }
        }
        return results
    }
}

// MARK: - UIKit Image Picker Bridge
public struct WaageImagePicker: UIViewControllerRepresentable {
    public var sourceType: UIImagePickerController.SourceType
    public var onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: WaageImagePicker

        init(_ parent: WaageImagePicker) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

