import SwiftUI

public struct CareZoneSelectorView: View {
    @Binding public var selectedZone: CareZone
    @ObservedObject var store = GrowCareStore.shared

    public init(selectedZone: Binding<CareZone>) {
        self._selectedZone = selectedZone
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CareZone.allCases) { zone in
                    zonePill(zone)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func zonePill(_ zone: CareZone) -> some View {
        let isSelected = selectedZone == zone
        let count = countForZone(zone)

        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedZone = zone
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: zone.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? CareTheme.bg : CareTheme.careLilac)

                Text(zone.shortLabel)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? CareTheme.bg : CareTheme.textPrimary)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(isSelected ? CareTheme.bg.opacity(0.2) : CareTheme.surfaceSubtle)
                        )
                        .foregroundColor(isSelected ? CareTheme.bg : CareTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? CareTheme.careLilac : CareTheme.surface)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? CareTheme.careLilac : CareTheme.border, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func countForZone(_ zone: CareZone) -> Int {
        if zone == .all {
            return store.scheduledRoutines(for: store.selectedDate).count + store.scheduledChores(for: store.selectedDate).count
        } else if zone == .chores {
            return store.scheduledChores(for: store.selectedDate).count
        } else {
            return store.scheduledRoutines(for: store.selectedDate, zone: zone).count
        }
    }
}

