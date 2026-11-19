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
                            .foregroundColor(GymTheme.textPrimary)
                            .tracking(0.8)

                        if let badge = badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.sageGreen)
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
                            .foregroundColor(GymTheme.warmSand)
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
                        .foregroundColor(GymTheme.textMuted)
                        .padding(4)
                }
                .buttonStyle(AppleTactileButtonStyle())
            }

            if isExpanded.wrappedValue {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16)
    }
}

// MARK: - FlowLayout (Wrapping Horizontal Layout for Tag Chips)
public struct FlowLayout<Content: View>: View {
    public let spacing: CGFloat
    public let content: () -> Content

    public init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        _FlowLayout(spacing: spacing) {
            content()
        }
    }
}

private struct _FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var maxWidth: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + (currentRowWidth > 0 ? spacing : 0) > containerWidth {
                totalHeight += currentRowHeight + (totalHeight > 0 ? spacing : 0)
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                if currentRowWidth > 0 { currentRowWidth += spacing }
                currentRowWidth += size.width
                currentRowHeight = max(currentRowHeight, size.height)
            }
            maxWidth = max(maxWidth, currentRowWidth)
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += currentRowHeight + spacing
                x = bounds.minX
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

// MARK: - TargetMusclesCardView (Pill Breakdown Card for Exercise Detail)
public struct TargetMusclesCardView: View {
    public let primaryMuscles: [String]
    public let secondaryMuscles: [String]
    public let stabilizers: [String]
    public var onViewDetails: (() -> Void)?

    public init(
        primaryMuscles: [String],
        secondaryMuscles: [String] = [],
        stabilizers: [String] = [],
        onViewDetails: (() -> Void)? = nil
    ) {
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.stabilizers = stabilizers
        self.onViewDetails = onViewDetails
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ZIELMUSKEL-VERTEILUNG")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(GymTheme.textMuted)
                Spacer()
                if let action = onViewDetails {
                    Button("Details") { action() }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.sageGreen)
                }
            }

            if !primaryMuscles.isEmpty {
                muscleRow(label: "Primaer", muscles: primaryMuscles, accent: GymTheme.cancelRed)
            }
            if !secondaryMuscles.isEmpty {
                muscleRow(label: "Sekundaer", muscles: secondaryMuscles, accent: GymTheme.warmAmber)
            }
            if !stabilizers.isEmpty {
                muscleRow(label: "Stabilisatoren", muscles: stabilizers, accent: GymTheme.sageGreen)
            }
        }
        .padding(14)
        .somaCard(borderColor: GymTheme.border, background: GymTheme.surface)
    }

    private func muscleRow(label: String, muscles: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(accent)
                .tracking(0.8)
            FlowLayout(spacing: 6) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.15))
                        .foregroundColor(accent)
                        .cornerRadius(6)
                }
            }
        }
    }
}
