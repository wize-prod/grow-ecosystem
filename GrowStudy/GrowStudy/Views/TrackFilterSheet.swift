import SwiftUI

public struct TrackFilterSheet: View {
    @Binding var selectedTrackFilter: StudyTrack?
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                StudyTheme.bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    Text("PFEILER FILTERN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(.horizontal, 4)

                    Button {
                        selectedTrackFilter = nil
                        HapticFeedback.selection()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(StudyTheme.strongBlue)
                            Text("Alle 4 Pfeiler anzeigen")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(StudyTheme.textPrimary)
                            Spacer()
                            if selectedTrackFilter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(StudyTheme.sageGreen)
                            }
                        }
                        .padding(14)
                        .background(StudyTheme.surface)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    ForEach(StudyTrack.allCases) { track in
                        Button {
                            selectedTrackFilter = track
                            HapticFeedback.selection()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: track.systemImage)
                                    .foregroundColor(StudyTheme.strongBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(StudyTheme.textPrimary)
                                    Text(track.deadlineNote)
                                        .font(.system(size: 11))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                                Spacer()
                                if selectedTrackFilter == track {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(StudyTheme.sageGreen)
                                }
                            }
                            .padding(14)
                            .background(StudyTheme.surface)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Fahrplan Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(StudyTheme.strongBlue)
                }
            }
        }
    }
}
