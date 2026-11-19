import SwiftUI

public struct CollapsibleSection<Content: View>: View {
    public let title: String
    public var badge: String? = nil
    @State private var internalExpanded: Bool
    private var externalBinding: Binding<Bool>?
    public var infoAction: (() -> Void)? = nil
    public let content: Content

    private var isExpanded: Binding<Bool> {
        if let binding = externalBinding {
            return binding
        } else {
            return $internalExpanded
        }
    }

    public init(
        title: String,
        badge: String? = nil,
        isExpanded: Binding<Bool>,
        infoAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.badge = badge
        self._internalExpanded = State(initialValue: isExpanded.wrappedValue)
        self.externalBinding = isExpanded
        self.infoAction = infoAction
        self.content = content()
    }

    public init(
        title: String,
        badge: String? = nil,
        initiallyExpanded: Bool = true,
        infoAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.badge = badge
        self._internalExpanded = State(initialValue: initiallyExpanded)
        self.externalBinding = nil
        self.infoAction = infoAction
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isExpanded.wrappedValue.toggle()
                    }
                    HapticFeedback.light()
                }) {
                    HStack(spacing: 8) {
                        Text(title.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(StudyTheme.textPrimary)
                            .tracking(0.8)

                        if let badge = badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(StudyTheme.sageGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.8))
                        }

                        Spacer()
                    }
                }
                .buttonStyle(AppleTactileButtonStyle())

                if let info = infoAction {
                    Button(action: info) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(StudyTheme.warmSand)
                            .padding(4)
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isExpanded.wrappedValue.toggle()
                    }
                    HapticFeedback.light()
                }) {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(4)
                }
                .buttonStyle(AppleTactileButtonStyle())
            }

            if isExpanded.wrappedValue {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .wellnessCard(borderColor: StudyTheme.border, cornerRadius: 18)
    }
}
