import SwiftUI

public struct GymCircularProfileButton: View {
    @ObservedObject private var store = GymStore.shared
    @ObservedObject private var userAccount = UserAccountService.shared
    public var onTap: () -> Void

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            ZStack {
                Circle()
                    .fill(GymTheme.surfaceElevated)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(GymTheme.border, lineWidth: 1)
                    )

                Text(userAccount.currentAccount.initial)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Profil und Einstellungen oeffnen")
    }
}

