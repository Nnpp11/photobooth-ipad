import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore
    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1

    private var event: Event? { eventStore.activeEvent }

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            VStack(spacing: 0) {
                Spacer()
                headerSection
                Spacer()
                mainCTA
                Spacer(minLength: DS.Spacing.xxl)
                modeSelector
                Spacer(minLength: DS.Spacing.xl)
                bottomBar
            }
            .padding(.horizontal, DS.Spacing.xxl)
        }
        .onAppear {
            withAnimation(DS.Animation.slow.delay(0.1)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }

    // MARK: - Background
    var backgroundLayer: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            // Radial gold glow
            RadialGradient(
                colors: [
                    Color(hex: "#C9A84C").opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Corner decorations
            GeometryReader { geo in
                Group {
                    cornerDecoration(at: .topLeading, geo: geo)
                    cornerDecoration(at: .topTrailing, geo: geo)
                    cornerDecoration(at: .bottomLeading, geo: geo)
                    cornerDecoration(at: .bottomTrailing, geo: geo)
                }
            }
        }
    }

    func cornerDecoration(at alignment: Alignment, geo: GeometryProxy) -> some View {
        let size: CGFloat = 120
        let isTop = alignment == .topLeading || alignment == .topTrailing
        let isLeading = alignment == .topLeading || alignment == .bottomLeading

        return Path { path in
            let x: CGFloat = isLeading ? 0 : geo.size.width - size
            let y: CGFloat = isTop ? 0 : geo.size.height - size
            path.move(to: CGPoint(x: x + (isLeading ? 0 : size), y: y))
            path.addLine(to: CGPoint(x: x + (isLeading ? size * 0.4 : size * 0.6), y: y))
            path.move(to: CGPoint(x: x + (isLeading ? 0 : size), y: y))
            path.addLine(to: CGPoint(x: x + (isLeading ? 0 : size), y: y + (isTop ? size * 0.4 : -size * 0.4)))
        }
        .stroke(DS.Gradient.gold, lineWidth: 1.5)
        .opacity(appeared ? 0.6 : 0)
        .animation(DS.Animation.slow.delay(0.3), value: appeared)
    }

    // MARK: - Header
    var headerSection: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Logo / Icon
            ZStack {
                Circle()
                    .fill(DS.Color.goldDim)
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseScale)

                Image(systemName: "camera.aperture")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(DS.Gradient.gold)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.6)
            .animation(DS.Animation.spring.delay(0.15), value: appeared)

            // Event name
            VStack(spacing: DS.Spacing.sm) {
                Text(event?.name ?? "Photobooth")
                    .font(DS.Font.display(56, weight: .thin))
                    .foregroundColor(DS.Color.offWhite)
                    .multilineTextAlignment(.center)
                    .overlay(
                        GeometryReader { geo in
                            DS.Gradient.shimmer
                                .frame(width: geo.size.width * 0.5)
                                .offset(x: geo.size.width * shimmerOffset)
                                .clipped()
                        }
                    )
                    .clipped()

                if let subtitle = event?.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DS.Font.label(18, weight: .light))
                        .foregroundColor(DS.Color.muted)
                        .tracking(3)
                        .textCase(.uppercase)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(DS.Animation.smooth.delay(0.25), value: appeared)
        }
    }

    // MARK: - Main CTA
    var mainCTA: some View {
        Button {
            if let event = eventStore.activeEvent {
                appState.startSession(eventId: event.id)
            }
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: DS.Radius.full)
                    .fill(DS.Gradient.gold)
                    .frame(height: 80)
                    .shadow(color: Color(hex: "#C9A84C").opacity(0.4), radius: 20, y: 8)

                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Prendre une photo")
                        .font(DS.Font.label(22, weight: .semibold))
                        .tracking(0.5)
                }
                .foregroundColor(DS.Color.background)
            }
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.spring.delay(0.4), value: appeared)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Mode Selector (si plusieurs modes actifs)
    var modeSelector: some View {
        Group {
            if let event = event {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(CaptureMode.allCases) { mode in
                            ModePill(
                                mode: mode,
                                isSelected: event.captureMode == mode
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xxl)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.5), value: appeared)
    }

    // MARK: - Bottom bar
    var bottomBar: some View {
        HStack {
            if let hashtag = event?.hashtag, !hashtag.isEmpty {
                Text(hashtag)
                    .font(DS.Font.mono(14))
                    .foregroundColor(DS.Color.gold.opacity(0.7))
            }
            Spacer()
            Text(event?.date.formatted(date: .long, time: .omitted) ?? "")
                .font(DS.Font.caption(13))
                .foregroundColor(DS.Color.muted)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .opacity(appeared ? 0.8 : 0)
        .animation(DS.Animation.smooth.delay(0.6), value: appeared)
    }
}

// MARK: - Mode Pill
struct ModePill: View {
    let mode: CaptureMode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.system(size: 13))
            Text(mode.rawValue)
                .font(DS.Font.label(13))
        }
        .foregroundColor(isSelected ? DS.Color.background : DS.Color.gold)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            Capsule()
                .fill(isSelected ? DS.Gradient.gold : DS.Gradient.goldSubtle)
                .overlay(
                    Capsule()
                        .strokeBorder(DS.Gradient.gold, lineWidth: isSelected ? 0 : 1)
                )
        )
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DS.Animation.fast, value: configuration.isPressed)
    }
}
