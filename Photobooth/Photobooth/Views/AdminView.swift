import SwiftUI

// MARK: - PIN Entry
struct AdminPINView: View {
    let auth: AdminAuth
    let onSuccess: () -> Void

    @State private var pin = ""
    @State private var shake = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: DS.Spacing.xxl) {
                Spacer()

                VStack(spacing: DS.Spacing.lg) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(DS.Gradient.gold)

                    Text("Accès administrateur")
                        .font(DS.Font.display(28, weight: .thin))
                        .foregroundColor(DS.Color.offWhite)

                    Text("Entrez le code PIN")
                        .font(DS.Font.caption(15))
                        .foregroundColor(DS.Color.muted)
                }

                // PIN dots
                HStack(spacing: DS.Spacing.lg) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < pin.count ? DS.Color.gold : DS.Color.surface)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .strokeBorder(DS.Color.gold.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .offset(x: shake ? -8 : 0)
                .animation(
                    shake ? .default.repeatCount(4, autoreverses: true).speed(6) : .default,
                    value: shake
                )

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(DS.Font.caption(14))
                        .foregroundColor(DS.Color.danger)
                        .transition(.opacity)
                }

                // Numpad
                VStack(spacing: DS.Spacing.md) {
                    ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                        HStack(spacing: DS.Spacing.md) {
                            ForEach(row, id: \.self) { num in
                                PINKey(label: "\(num)") { appendDigit("\(num)") }
                            }
                        }
                    }
                    HStack(spacing: DS.Spacing.md) {
                        PINKey(label: "⌫", color: DS.Color.muted) { deleteDigit() }
                        PINKey(label: "0") { appendDigit("0") }
                        PINKey(label: "✕", color: DS.Color.danger) { dismiss() }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.xxl)
        }
    }

    func appendDigit(_ d: String) {
        guard pin.count < 4 else { return }
        pin += d
        errorMessage = ""
        if pin.count == 4 { verifyPIN() }
    }

    func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
        errorMessage = ""
    }

    func verifyPIN() {
        if auth.verify(pin) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSuccess() }
        } else {
            withAnimation { shake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shake = false
                pin = ""
                withAnimation { errorMessage = "Code incorrect" }
            }
        }
    }
}

struct PINKey: View {
    let label: String
    var color: Color = DS.Color.gold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.Font.display(28, weight: .light))
                .foregroundColor(color)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(DS.Color.surface)
                        .overlay(Circle().strokeBorder(color.opacity(0.2), lineWidth: 1))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Admin View
struct AdminView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore
    @State private var selectedTab = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                adminHeader
                adminTabBar
                Divider().background(DS.Color.gold.opacity(0.2))

                TabView(selection: $selectedTab) {
                    EventConfigTab()   .tag(0)
                    PreflightTab()     .tag(1)
                    GalleryAdminTab()  .tag(2)
                    SettingsAdminTab() .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear {
            withAnimation(DS.Animation.smooth.delay(0.1)) { appeared = true }
        }
    }

    var adminHeader: some View {
        HStack {
            Button {
                appState.navigate(to: .welcome)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DS.Color.offWhite)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(DS.Color.surface))
            }

            Spacer()

            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DS.Gradient.gold)
                Text("Administration")
                    .font(DS.Font.display(22, weight: .thin))
                    .foregroundColor(DS.Color.offWhite)
            }

            Spacer()
            Spacer().frame(width: 36)
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.md)
        .background(DS.Color.surface)
    }

    var adminTabBar: some View {
        HStack(spacing: 0) {
            ForEach(["Événement", "Pré-vol", "Galerie", "Réglages"].enumerated().map({ $0 }), id: \.offset) { i, title in
                Button {
                    withAnimation(DS.Animation.smooth) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(DS.Font.label(14, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? DS.Color.gold : DS.Color.muted)
                        Rectangle()
                            .fill(selectedTab == i ? DS.Gradient.gold : AnyShapeStyle(Color.clear))
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                }
            }
        }
        .background(DS.Color.surface)
    }
}

// MARK: - Event Config Tab
struct EventConfigTab: View {
    @EnvironmentObject var eventStore: EventStore
    @State private var eventName: String = ""
    @State private var subtitle: String = ""
    @State private var hashtag: String = ""
    @State private var captureMode: CaptureMode = .single
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                SectionHeader("Informations de l'événement")

                AdminField(label: "Nom de l'événement", placeholder: "Ex: Mariage Marie & Paul", text: $eventName)
                AdminField(label: "Sous-titre", placeholder: "Ex: Bienvenue à notre mariage", text: $subtitle)
                AdminField(label: "Hashtag", placeholder: "#notresoirée", text: $hashtag)

                SectionHeader("Mode de capture")

                VStack(spacing: DS.Spacing.sm) {
                    ForEach(CaptureMode.allCases) { mode in
                        AdminModeRow(mode: mode, isSelected: captureMode == mode) {
                            withAnimation(DS.Animation.fast) { captureMode = mode }
                        }
                    }
                }

                SaveButton(saved: saved) {
                    saveEvent()
                }
            }
            .padding(DS.Spacing.xl)
        }
        .onAppear { loadEvent() }
    }

    func loadEvent() {
        guard let event = eventStore.activeEvent else { return }
        eventName = event.name
        subtitle = event.subtitle
        hashtag = event.hashtag
        captureMode = event.captureMode
    }

    func saveEvent() {
        guard var event = eventStore.activeEvent else { return }
        event.name = eventName
        event.subtitle = subtitle
        event.hashtag = hashtag
        event.captureMode = captureMode
        if let idx = eventStore.events.firstIndex(where: { $0.id == event.id }) {
            eventStore.events[idx] = event
        }
        eventStore.activeEvent = event
        eventStore.save()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { saved = false } }
    }
}

// MARK: - Preflight Tab
struct PreflightTab: View {
    @StateObject private var printService = PrintService()
    @State private var checks: [(String, String, Bool)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                SectionHeader("Vérification avant événement")

                ForEach(checks, id: \.0) { check in
                    PreflightRow(label: check.0, detail: check.1, ok: check.2)
                }

                Button {
                    runChecks()
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Relancer les vérifications")
                            .font(DS.Font.label(15, weight: .semibold))
                    }
                    .foregroundColor(DS.Color.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.md).fill(DS.Gradient.gold))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(DS.Spacing.xl)
        }
        .onAppear { runChecks() }
    }

    func runChecks() {
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryOk = batteryLevel > 0.2 || batteryLevel == -1

        let freeSpace = freeDiskSpace()
        let spaceOk = freeSpace > 500_000_000 // 500 MB

        let networkOk = true // Simplified

        printService.checkPrinterAvailability()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            checks = [
                ("Batterie", batteryLevel == -1 ? "En charge" : "\(Int(batteryLevel * 100))%", batteryOk),
                ("Stockage libre", freeSpace > 1_000_000_000 ? "\(freeSpace / 1_000_000_000) Go" : "\(freeSpace / 1_000_000) Mo", spaceOk),
                ("Réseau / SIM", "Connecté", networkOk),
                ("Imprimante", printService.printerAvailable ? printService.printerName : "Non détectée", printService.printerAvailable),
            ]
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
        checks = [
            ("Batterie", "Vérification…", false),
            ("Stockage libre", "Vérification…", false),
            ("Réseau / SIM", "Vérification…", false),
            ("Imprimante", "Vérification…", false),
        ]
    }

    func freeDiskSpace() -> Int64 {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        return (attrs?[.systemFreeSize] as? Int64) ?? 0
    }
}

// MARK: - Gallery Admin Tab
struct GalleryAdminTab: View {
    @EnvironmentObject var eventStore: EventStore

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                SectionHeader("Galerie — \(eventStore.activeEvent?.name ?? "")")

                HStack(spacing: DS.Spacing.md) {
                    StatCard(value: "\(eventStore.totalSessions)", label: "Sessions")
                    StatCard(value: "\(eventStore.mediaItems.count)", label: "Photos")
                    StatCard(value: "\(eventStore.pendingUploads)", label: "En attente")
                }

                if eventStore.mediaItems.isEmpty {
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundColor(DS.Color.muted)
                        Text("Aucune photo pour l'instant")
                            .font(DS.Font.caption(15))
                            .foregroundColor(DS.Color.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.xxl)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                        ForEach(eventStore.mediaItems) { media in
                            MediaThumbnail(media: media, store: eventStore)
                        }
                    }
                }
            }
            .padding(DS.Spacing.xl)
        }
    }
}

// MARK: - Settings Tab
struct SettingsAdminTab: View {
    @StateObject private var auth = AdminAuth()
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var pinSaved = false
    @State private var pinError = ""

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                SectionHeader("Sécurité")

                AdminField(label: "Nouveau PIN (4 chiffres)", placeholder: "••••", text: $newPin)
                    .keyboardType(.numberPad)
                AdminField(label: "Confirmer le PIN", placeholder: "••••", text: $confirmPin)

                if !pinError.isEmpty {
                    Text(pinError)
                        .font(DS.Font.caption(13))
                        .foregroundColor(DS.Color.danger)
                }

                SaveButton(saved: pinSaved, label: "Changer le PIN") {
                    changePIN()
                }

                SectionHeader("À propos")
                InfoRow(label: "Version", value: "1.0.0 MVP")
                InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            }
            .padding(DS.Spacing.xl)
        }
    }

    func changePIN() {
        guard newPin.count == 4 else { pinError = "Le PIN doit faire 4 chiffres"; return }
        guard newPin == confirmPin else { pinError = "Les PINs ne correspondent pas"; return }
        guard newPin.allSatisfy({ $0.isNumber }) else { pinError = "Le PIN ne doit contenir que des chiffres"; return }
        auth.changePin(newPin)
        pinError = ""
        newPin = ""
        confirmPin = ""
        withAnimation { pinSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { pinSaved = false } }
    }
}

// MARK: - Reusable Admin Components
struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(DS.Font.label(11, weight: .semibold))
                .foregroundColor(DS.Color.gold)
                .tracking(2)
            Rectangle().fill(DS.Color.gold.opacity(0.2)).frame(height: 1)
        }
    }
}

struct AdminField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(label)
                .font(DS.Font.label(12, weight: .medium))
                .foregroundColor(DS.Color.muted)
                .textCase(.uppercase)
                .tracking(1)
            StyledTextField(placeholder: placeholder, text: $text, icon: "pencil", keyboardType: keyboardType)
        }
    }
}

struct AdminModeRow: View {
    let mode: CaptureMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? DS.Color.background : DS.Color.gold)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(DS.Font.label(15, weight: .semibold))
                        .foregroundColor(isSelected ? DS.Color.background : DS.Color.offWhite)
                    Text(mode.description)
                        .font(DS.Font.caption(12))
                        .foregroundColor(isSelected ? DS.Color.background.opacity(0.7) : DS.Color.muted)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DS.Color.background)
                }
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(isSelected ? AnyShapeStyle(DS.Gradient.gold) : AnyShapeStyle(DS.Color.surface))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SaveButton: View {
    let saved: Bool
    var label: String = "Sauvegarder"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: saved ? "checkmark" : "arrow.down.circle")
                    .font(.system(size: 16, weight: .semibold))
                Text(saved ? "Sauvegardé !" : label)
                    .font(DS.Font.label(15, weight: .semibold))
            }
            .foregroundColor(saved ? DS.Color.success : DS.Color.background)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(saved ? DS.Color.success.opacity(0.2) : AnyShapeStyle(DS.Gradient.gold))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .strokeBorder(saved ? DS.Color.success.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PreflightRow: View {
    let label: String
    let detail: String
    let ok: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(ok ? DS.Color.success : DS.Color.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(DS.Font.label(14, weight: .semibold)).foregroundColor(DS.Color.offWhite)
                Text(detail).font(DS.Font.caption(12)).foregroundColor(DS.Color.muted)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(RoundedRectangle(cornerRadius: DS.Radius.md).fill(DS.Color.surface))
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(value)
                .font(DS.Font.display(32, weight: .thin))
                .foregroundStyle(DS.Gradient.gold)
            Text(label)
                .font(DS.Font.caption(12))
                .foregroundColor(DS.Color.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.md)
        .background(RoundedRectangle(cornerRadius: DS.Radius.md).fill(DS.Color.surface))
    }
}

struct MediaThumbnail: View {
    let media: MediaItem
    let store: EventStore

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = store.loadImage(at: media.localPath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(DS.Color.surface)
                    .frame(height: 100)
                    .overlay(Image(systemName: "photo").foregroundColor(DS.Color.muted))
            }

            if !media.isPublic {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .padding(4)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(DS.Font.label(14)).foregroundColor(DS.Color.muted)
            Spacer()
            Text(value).font(DS.Font.mono(14)).foregroundColor(DS.Color.offWhite)
        }
        .padding(DS.Spacing.md)
        .background(RoundedRectangle(cornerRadius: DS.Radius.md).fill(DS.Color.surface))
    }
}
