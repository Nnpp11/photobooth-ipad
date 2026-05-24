import SwiftUI

struct PreviewView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore
    @State private var appeared = false
    @State private var showRetakeConfirm = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: DS.Spacing.lg)
                photoPreview
                Spacer(minLength: DS.Spacing.xl)
                actionButtons
                Spacer(minLength: DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .onAppear {
            withAnimation(DS.Animation.smooth.delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header
    var header: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text("Votre photo")
                    .font(DS.Font.display(28, weight: .thin))
                    .foregroundColor(DS.Color.offWhite)
                Text("Valider ou recommencer ?")
                    .font(DS.Font.caption(14))
                    .foregroundColor(DS.Color.muted)
            }
            Spacer()
        }
        .padding(.top, DS.Spacing.xl)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(DS.Animation.smooth.delay(0.1), value: appeared)
    }

    // MARK: - Photo Preview
    var photoPreview: some View {
        GeometryReader { geo in
            ZStack {
                if let image = appState.finalImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
                        .goldBorder(width: 1.5, cornerRadius: DS.Radius.lg)
                        .shadow(color: Color(hex: "#C9A84C").opacity(0.2), radius: 24)
                        .scaleEffect(appeared ? 1 : 0.92)
                        .opacity(appeared ? 1 : 0)
                        .animation(DS.Animation.spring.delay(0.2), value: appeared)
                } else {
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(DS.Color.surface)
                        .overlay(
                            ProgressView()
                                .tint(DS.Color.gold)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Action Buttons
    var actionButtons: some View {
        HStack(spacing: DS.Spacing.lg) {
            // Retake
            Button {
                showRetakeConfirm = true
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Recommencer")
                        .font(DS.Font.label(16))
                }
                .foregroundColor(DS.Color.offWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(DS.Color.surface)
                        .goldBorder(width: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Continue
            Button {
                appState.navigate(to: .consent)
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Text("Continuer")
                        .font(DS.Font.label(16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(DS.Color.background)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(DS.Gradient.gold)
                        .shadow(color: Color(hex: "#C9A84C").opacity(0.35), radius: 12, y: 4)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(DS.Animation.smooth.delay(0.35), value: appeared)
        .alert("Recommencer ?", isPresented: $showRetakeConfirm) {
            Button("Annuler", role: .cancel) {}
            Button("Recommencer", role: .destructive) {
                appState.navigate(to: .capture)
            }
        } message: {
            Text("La photo actuelle sera supprimée.")
        }
    }
}
