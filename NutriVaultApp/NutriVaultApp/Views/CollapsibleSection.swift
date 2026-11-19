import SwiftUI

public struct CollapsibleSection<Content: View>: View {
    public let title: String
    public let badge: String?
    public let infoAction: (() -> Void)?
    @Binding public var isExpanded: Bool
    @ViewBuilder public let content: () -> Content

    public init(
        title: String,
        badge: String? = nil,
        isExpanded: Binding<Bool>,
        infoAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.badge = badge
        self.infoAction = infoAction
        self._isExpanded = isExpanded
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row
            HStack(spacing: 8) {
                // Title and Badge Tap Area
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)

                        if let badge = badge, !badge.isEmpty {
                            Text(badge)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                    }
                }
                .buttonStyle(AppleTactileButtonStyle())

                Spacer()

                // Optional Info Button (ⓘ)
                if let infoAction = infoAction {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        infoAction()
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.textSecondary)
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }

                // Chevron Toggle
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(AppleTactileButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Collapsible Content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.8)
        )
    }
}
