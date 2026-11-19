import SwiftUI

public struct ExplanationDetail: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    public let text: String

    public init(id: UUID = UUID(), label: String, text: String) {
        self.id = id
        self.label = label
        self.text = text
    }
}

public struct InfoExplanationItem: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let category: String
    public let summary: String
    public let details: [ExplanationDetail]

    public init(id: UUID = UUID(), title: String, category: String, summary: String, details: [ExplanationDetail] = []) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.details = details
    }
}

public struct InfoExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let item: InfoExplanationItem

    public init(item: InfoExplanationItem) {
        self.item = item
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category & Title Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.warmSand)
                            .tracking(1.0)
                        Text(item.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .wellnessCard()

                    // Summary Block
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ERLÄUTERUNG & ZIELSETZUNG")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)

                        Text(item.summary)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.textPrimary)
                            .lineSpacing(3)
                    }
                    .wellnessCard()

                    // Detailed Points
                    if !item.details.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DETAILS & PARAMETER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)

                            VStack(spacing: 8) {
                                ForEach(item.details) { detail in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(Theme.sageGreen)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(detail.label)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.warmSand)
                                            Text(detail.text)
                                                .font(.system(size: 12, weight: .regular, design: .default))
                                                .foregroundColor(Theme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                                }
                            }
                        }
                        .wellnessCard()
                    }

                    // Done Button at Bottom
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        dismiss()
                    }) {
                        Text("Verstanden")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                    }
                    .padding(.top, 8)
                }
                .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textMuted)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
