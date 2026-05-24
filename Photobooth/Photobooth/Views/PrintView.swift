import SwiftUI

struct PrintView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var printService = PrintService()

    @State private var copies: Int = 1
    @State private var appeared = false
    @State private var printTriggered = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                printHeader
                Spacer(minLength: DS.Spacing.lg)
                printContent
                Spacer(minLength: DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .onAppear {
            withAnimation(DS.Animation.smooth.delay(0.1)) { appeared = true }
            printService.checkPrinterAvailability()
        }
    }

    // MARK: - Header
    var printHeader: some View {
        HStack {
            Button {
                appState.navigate(to: .share)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(DS.Color.offWhite)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DS.Color.surface))
            }
            Spacer()
            Text("Impression")
                .font(DS.Font.display(24, weight: .thin))
                .foregroundColor(DS.Color.offWhite)
            Spacer()
            Spacer().frame(width: 44)
        }
        .padding(.top, DS.Spacing.xl)
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.1), value: appeared)
    }

    // MARK: - Content
    var printContent: some View {
        HStack(alignment: .top, spacing: DS.Spacing.xxl) {
            // Preview
            printPreview

            // Controls
            VStack(spacing: DS.Spacing.lg) {
                printerStatus
                copiesSelector
                printButton
                if let error = printService.lastError {
                    errorBanner(error)
                }
            }
            .frame(maxWidth: 320)
        }
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.2), value: appeared)
    }

    // MARK: - Preview
    var printPreview: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("Aperçu impression")
                .font(DS.Font.label(13))
                .foregroundColor(DS.Color.muted)
                .tracking(1)
                .textCase(.uppercase)

            // 10x15 aspect ratio preview
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 12)

                    if let image = appState.finalImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                    }
                }
            }
            .aspectRatio(2.0/3.0, contentMode: .fit) // 10x15 = 2:3

            Text("Format 10×15 cm")
                .font(DS.Font.caption(13))
                .foregroundColor(DS.Color.muted)
        }
    }

    // MARK: - Printer Status
    var printerStatus: some View {
        HStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(printService.printerAvailable
                          ? DS.Color.success.opacity(0.2)
                          : DS.Color.danger.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: printService.printerAvailable ? "printer.fill" : "printer.dotmatrix")
                    .font(.system(size: 18))
                    .foregroundColor(printService.printerAvailable ? DS.Color.success : DS.Color.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(printService.printerAvailable ? "Imprimante prête" : "Aucune imprimante")
                    .font(DS.Font.label(14, weight: .semibold))
                    .foregroundColor(printService.printerAvailable ? DS.Color.success : DS.Color.danger)
                Text(printService.printerAvailable
                     ? printService.printerName
                     : "Vérifiez le Wi-Fi et l'imprimante")
                    .font(DS.Font.caption(12))
                    .foregroundColor(DS.Color.muted)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                printService.checkPrinterAvailability()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(DS.Color.gold)
            }
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(DS.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .strokeBorder(
                            printService.printerAvailable
                            ? DS.Color.success.opacity(0.3)
                            : DS.Color.danger.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Copies Selector
    var copiesSelector: some View {
        HStack {
            Text("Nombre de copies")
                .font(DS.Font.label(14))
                .foregroundColor(DS.Color.offWhite)

            Spacer()

            HStack(spacing: DS.Spacing.md) {
                Button {
                    if copies > 1 { withAnimation(DS.Animation.fast) { copies -= 1 } }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(copies > 1 ? DS.Color.gold : DS.Color.muted)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(DS.Color.surface))
                }
                .disabled(copies <= 1)

                Text("\(copies)")
                    .font(DS.Font.mono(22))
                    .foregroundColor(DS.Color.offWhite)
                    .frame(width: 32)
                    .contentTransition(.numericText())

                Button {
                    if copies < 4 { withAnimation(DS.Animation.fast) { copies += 1 } }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(copies < 4 ? DS.Color.gold : DS.Color.muted)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(DS.Color.surface))
                }
                .disabled(copies >= 4)
            }
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(DS.Color.surface)
        )
    }

    // MARK: - Print Button
    var printButton: some View {
        Button {
            triggerPrint()
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                if printService.isPrinting {
                    ProgressView()
                        .tint(DS.Color.background)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(printService.isPrinting ? "Impression en cours…" : "Imprimer \(copies > 1 ? "\(copies) copies" : "")")
                    .font(DS.Font.label(17, weight: .semibold))
            }
            .foregroundColor(DS.Color.background)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(printService.printerAvailable
                          ? AnyShapeStyle(DS.Gradient.gold)
                          : AnyShapeStyle(DS.Color.surface))
                    .shadow(
                        color: printService.printerAvailable
                            ? Color(hex: "#C9A84C").opacity(0.3) : .clear,
                        radius: 12, y: 4
                    )
            )
        }
        .disabled(!printService.printerAvailable || printService.isPrinting)
        .buttonStyle(ScaleButtonStyle())
    }

    func errorBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DS.Color.danger)
            Text(message)
                .font(DS.Font.caption(13))
                .foregroundColor(DS.Color.danger)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(DS.Color.danger.opacity(0.1))
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    func triggerPrint() {
        guard let image = appState.finalImage else { return }
        guard let vc = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else { return }

        printService.print(image: image, copies: copies, from: vc)
    }
}
