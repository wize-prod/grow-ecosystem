import SwiftUI

public struct StudyCircularTimerButton: View {
    @ObservedObject private var store = StudyStore.shared
    @State private var showingTimerSheet: Bool = false

    public init() {}

    private var minutes: Int {
        store.focusTimerSecondsRemaining / 60
    }

    private var seconds: Int {
        store.focusTimerSecondsRemaining % 60
    }

    public var body: some View {
        if store.isFocusTimerRunning {
            Button {
                HapticFeedback.light()
                showingTimerSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(StudyTheme.cyanAccent)

                    if let title = store.activeTimerTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(StudyTheme.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: 180, alignment: .leading)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(StudyTheme.textMuted)
                    }

                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.cyanAccent)

                    Button {
                        HapticFeedback.light()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            store.stopFocusTimer()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StudyTheme.textMuted)
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Timer beenden")
                }
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(StudyTheme.surfaceElevated)
                        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    Capsule()
                        .stroke(StudyTheme.cyanAccent.opacity(0.65), lineWidth: 1.2)
                )
            }
            .buttonStyle(AppleTactileButtonStyle())
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sheet(isPresented: $showingTimerSheet) {
                TimerFocusSheet(step: store.activeTimerStep, isSheet: true)
                    .environmentObject(store)
            }
        }
    }
}
