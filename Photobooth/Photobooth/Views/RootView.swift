import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            switch appState.currentScreen {
            case .welcome:
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))

            case .capture:
                CaptureView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))

            case .preview:
                PreviewView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))

            case .consent:
                ConsentView()
                    .transition(.move(edge: .bottom))

            case .share:
                ShareView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))

            case .print:
                PrintView()
                    .transition(.move(edge: .bottom))

            case .admin:
                AdminView()
                    .transition(.move(edge: .bottom))
            }

            // Admin shortcut — 5-tap on corner
            VStack {
                HStack {
                    Spacer()
                    AdminTriggerButton()
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .animation(DS.Animation.smooth, value: appState.currentScreen)
    }
}

// MARK: - Admin trigger (hidden tap zone)
struct AdminTriggerButton: View {
    @EnvironmentObject var appState: AppState
    @State private var tapCount = 0
    @State private var showPIN = false
    @StateObject private var auth = AdminAuth()

    var body: some View {
        Button {
            tapCount += 1
            if tapCount >= 5 {
                tapCount = 0
                showPIN = true
            }
        } label: {
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .sheet(isPresented: $showPIN) {
            AdminPINView(auth: auth) {
                appState.navigate(to: .admin)
            }
        }
    }
}
