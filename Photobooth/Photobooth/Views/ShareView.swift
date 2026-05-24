import SwiftUI

struct ShareView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore
    @StateObject private var printService = PrintService()

    @State private var appeared = false
    @State private var savedToPhotos = false
    @State private var mediaItem: MediaItem?
    @State private var autoReturnCountdown: Int = 30
    @State private var timer: Timer?

    private var qrContent: String {
        if let media = mediaItem, let url = media.remoteUrl {
            return url
        }
        // Fallback: local identifier
        return "photobooth://\(appState.currentSession?.id.uuidString ?? "unknown")"
    }

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: DS.Spacing.lg)
                mainContent
                Spacer(minLength: DS.Spacing.lg)
                bottomActions
                Spacer(minLength: DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .onAppear {
            withAnimation(DS.Animation.smooth.delay(0.1)) { appeared = true }
            saveMedia()
            printService.checkPrinterAvailability()
            startAutoReturn()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Header
    var header: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack {
                Spacer()
                // Auto-return countdown
                Text("Retour dans \(autoReturnCountdown)s")
                    .font(DS.Font.mono(13))
                    .foregroundColor(DS.Color.muted)
            }
            .padding(.top, DS.Spacing.xl)

            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(DS.Gradient.gold)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(DS.Animation.spring.delay(0.15), value: appeared)

                Text("Votre photo est prête !")
                    .font(DS.Font.display(32, weight: .thin))
                    .foregroundColor(DS.Color.offWhite)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.1), value: appeared)
    }

    // MARK: - Main Content
    var mainContent: some View {
        HStack(alignment: .top, spacing: DS.Spacing.xl) {
            // Left: photo preview
            if let image = appState.finalImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .goldBorder(width: 1.5, cornerRadius: DS.Radius.md)
                    .shadow(color: Color(hex: "#C9A84C").opacity(0.2), radius: 16)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)
                    .animation(DS.Animation.spring.delay(0.2), value: appeared)
            }

            // Right: QR + share options
            VStack(spacing: DS.Spacing.lg) {
                qrSection
                shareButtons
            }
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : 30)
            .animation(DS.Animation.smooth.delay(0.3), value: appeared)
        }
    }

    // MARK: - QR Section
    var qrSection: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("Scannez pour récupérer")
                .font(DS.Font.label(13))
                .foregroundColor(DS.Color.muted)
                .tracking(1)
                .textCase(.uppercase)

            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(Color.white)
                    .frame(width: 200, height: 200)
                    .shadow(color: Color(hex: "#C9A84C").opacity(0.3), radius: 12)

                QRCodeView(content: qrContent, size: 180)
            }
            .goldBorder(width: 2, cornerRadius: DS.Radius.md)
        }
    }

    // MARK: - Share Buttons
    var shareButtons: some View {
        VStack(spacing: DS.Spacing.sm) {
            ShareActionButton(
                title: "Enregistrer",
                subtitle: "Dans la photothèque",
                icon: "arrow.down.to.line",
                isCompleted: savedToPhotos
            ) {
                if let image = appState.finalImage {
                    ShareService.saveToPhotos(image) { _ in
                        withAnimation(DS.Animation.spring) { savedToPhotos = true }
                    }
                }
            }

            ShareActionButton(
                title: "WhatsApp",
                subtitle: "Partager via WhatsApp",
                icon: "message.fill",
                tint: Color(hex: "#25D366")
            ) {
                _ = ShareService.shareViaWhatsApp(
                    text: "Ma photo du photobooth \(eventStore.activeEvent?.name ?? "") 🎉 \(qrContent)",
                    image: appState.finalImage
                )
            }

            ShareActionButton(
                title: "Email",
                subtitle: appState.currentSession?.guestEmail.isEmpty == false
                    ? appState.currentSession!.guestEmail
                    : "Envoyer par email",
                icon: "envelope.fill",
                tint: DS.Color.gold
            ) {
                ShareService.shareViaEmail(
                    to: appState.currentSession?.guestEmail ?? "",
                    subject: "Votre photo — \(eventStore.activeEvent?.name ?? "Photobooth")",
                    body: "Bonjour ! Voici votre photo du photobooth. Téléchargez-la ici : \(qrContent)",
                    image: appState.finalImage
                )
            }

            // Print button
            ShareActionButton(
                title: "Imprimer",
                subtitle: printService.printerAvailable ? printService.printerName : "Imprimante non détectée",
                icon: "printer.fill",
                tint: printService.printerAvailable ? DS.Color.gold : DS.Color.muted,
                chevron: true
            ) {
                appState.navigate(to: .print)
            }
        }
    }

    // MARK: - Bottom Actions
    var bottomActions: some View {
        Button {
            timer?.invalidate()
            appState.resetToWelcome()
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "house")
                    .font(.system(size: 16))
                Text("Terminer")
                    .font(DS.Font.label(16, weight: .semibold))
            }
            .foregroundColor(DS.Color.offWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Color.surface)
                    .goldBorder(width: 1, cornerRadius: DS.Radius.md)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.5), value: appeared)
    }

    // MARK: - Logic
    func saveMedia() {
        guard let session = appState.currentSession,
              let image = appState.finalImage else { return }

        var media = MediaItem(
            sessionId: session.id,
            eventId: session.eventId,
            type: .photo,
            isPublic: session.consentPublic
        )
        if let path = eventStore.saveImageLocally(image, for: media.id) {
            media.localPath = path
        }
        media.uploadStatus = .pending
        eventStore.addMedia(media)
        mediaItem = media
    }

    func startAutoReturn() {
        autoReturnCountdown = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if autoReturnCountdown > 0 {
                autoReturnCountdown -= 1
            } else {
                timer?.invalidate()
                appState.resetToWelcome()
            }
        }
    }
}

// MARK: - Share Action Button
struct ShareActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = DS.Color.gold
    var isCompleted: Bool = false
    var chevron: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? DS.Color.success.opacity(0.2) : tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isCompleted ? DS.Color.success : tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.Font.label(15, weight: .semibold))
                        .foregroundColor(isCompleted ? DS.Color.success : DS.Color.offWhite)
                    Text(subtitle)
                        .font(DS.Font.caption(12))
                        .foregroundColor(DS.Color.muted)
                        .lineLimit(1)
                }

                Spacer()

                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.muted)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .strokeBorder(isCompleted ? DS.Color.success.opacity(0.4) : DS.Color.gold.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
