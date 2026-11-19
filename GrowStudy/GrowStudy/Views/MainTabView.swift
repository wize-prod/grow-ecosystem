import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject private var store: StudyStore

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            StudyOverviewView()

            // Floating Timer Pill Button at bottom right (nur aktiv, wenn ein Timer läuft)
            StudyCircularTimerButton()
                .padding(.trailing, 20)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.isFocusTimerRunning)
        }
    }
}
