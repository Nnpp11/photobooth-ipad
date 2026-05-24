import SwiftUI
import AVFoundation

struct CaptureView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore
    @StateObject private var camera = CameraService()

    @State private var countdown: Int = 0
    @State private var isCountingDown = false
    @State private var capturedCount = 0
    @State private var flashOpacity: Double = 0
    @State private var showInstruction = true
    @State private var currentInstruction = "Regardez la caméra"
    @State private var frameImages: [UIImage] = []
    @State private var appeared = false

    private var event: Event? { eventStore.activeEvent }
    private var mode: CaptureMode { event?.captureMode ?? .single }
    private var totalFrames: Int { mode.frameCount }

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            // Camera preview
            CameraPreviewRepresentable(service: camera)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)
                .animation(DS.Animation.slow, value: appeared)

            // Vignette overlay
            DS.Gradient.vignette.ignoresSafeArea()

            // Flash effect
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // UI Overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                centerOverlay
                Spacer()
                bottomControls
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.vertical, DS.Spacing.xl)
        }
        .onAppear {
            camera.checkPermissionsAndSetup()
            withAnimation(DS.Animation.slow.delay(0.5)) { appeared = true }
        }
        .onDisappear {
            camera.stopSession()
        }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            Button {
                appState.resetToWelcome()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(DS.Color.offWhite)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }

            Spacer()

            if totalFrames > 1 {
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(0..<totalFrames, id: \.self) { i in
                        Circle()
                            .fill(i < capturedCount ? DS.Color.gold : DS.Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == capturedCount && isCountingDown ? 1.4 : 1)
                            .animation(DS.Animation.spring, value: capturedCount)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(Capsule().fill(Color.black.opacity(0.4)))
            }

            Spacer()
            Spacer().frame(width: 44) // balance
        }
    }

    // MARK: - Center Overlay
    var centerOverlay: some View {
        ZStack {
            // Instruction text
            if showInstruction && !isCountingDown {
                Text(currentInstruction)
                    .font(DS.Font.display(28, weight: .light))
                    .foregroundColor(DS.Color.offWhite.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Countdown
            if isCountingDown && countdown > 0 {
                Text("\(countdown)")
                    .font(DS.Font.display(160, weight: .thin))
                    .foregroundStyle(DS.Gradient.gold)
                    .shadow(color: Color(hex: "#C9A84C").opacity(0.5), radius: 30)
                    .transition(.scale.combined(with: .opacity))
                    .id(countdown) // force re-render for animation
            }

            // "Smile!" moment
            if isCountingDown && countdown == 0 {
                Text("✨")
                    .font(.system(size: 80))
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .id("smile")
            }
        }
        .animation(DS.Animation.spring, value: countdown)
        .animation(DS.Animation.smooth, value: isCountingDown)
    }

    // MARK: - Bottom Controls
    var bottomControls: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Mode label
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14))
                Text(mode.rawValue)
                    .font(DS.Font.label(14))
                Text("·")
                Text(mode.description)
                    .font(DS.Font.caption(14))
            }
            .foregroundColor(DS.Color.muted)

            // Shutter button
            ShutterButton(isCountingDown: isCountingDown) {
                startCapture()
            }
        }
    }

    // MARK: - Capture Logic
    func startCapture() {
        guard !isCountingDown else { return }
        isCountingDown = true
        showInstruction = false
        runCountdown(from: 3)
    }

    func runCountdown(from value: Int) {
        countdown = value
        if value == 0 {
            // Capture!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                triggerFlash()
                camera.capturePhoto { image in
                    guard let img = image else { return }
                    frameImages.append(img)
                    capturedCount += 1

                    if capturedCount < totalFrames {
                        // More frames needed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            currentInstruction = "Pose \(capturedCount + 1) sur \(totalFrames)"
                            showInstruction = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                showInstruction = false
                                runCountdown(from: 3)
                            }
                        }
                    } else {
                        // Done — compose and go to preview
                        composeFinal()
                    }
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                runCountdown(from: value - 1)
            }
        }
    }

    func triggerFlash() {
        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 1 }
        withAnimation(.easeIn(duration: 0.4).delay(0.1)) { flashOpacity = 0 }
    }

    func composeFinal() {
        let final: UIImage
        let template: PhotoTemplate? = nil // TODO: load from event

        switch mode {
        case .single:
            final = frameImages[0]
        case .strip:
            final = ImageComposer.composeStrip(images: frameImages, template: template)
        case .grid:
            final = ImageComposer.composeGrid(images: frameImages, template: template)
        case .gif:
            final = frameImages[0] // Preview shows first frame; GIF handled separately
        }

        appState.capturedImages = frameImages
        appState.finalImage = final
        isCountingDown = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigate(to: .preview)
        }
    }
}

// MARK: - Shutter Button
struct ShutterButton: View {
    let isCountingDown: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(DS.Gradient.gold, lineWidth: 3)
                    .frame(width: 90, height: 90)

                // Inner disc
                Circle()
                    .fill(
                        isCountingDown
                        ? AnyShapeStyle(DS.Color.muted)
                        : AnyShapeStyle(DS.Gradient.gold)
                    )
                    .frame(width: 70, height: 70)

                if isCountingDown {
                    ProgressView()
                        .tint(DS.Color.gold)
                }
            }
            .scaleEffect(pressed ? 0.92 : 1)
        }
        .disabled(isCountingDown)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DS.Animation.fast) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(DS.Animation.fast) { pressed = false }
                }
        )
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewRepresentable: UIViewRepresentable {
    let service: CameraService

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if let layer = service.previewLayer {
            uiView.setPreviewLayer(layer)
        }
    }
}

class CameraPreviewView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        if previewLayer == layer { return }
        previewLayer?.removeFromSuperlayer()
        previewLayer = layer
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
