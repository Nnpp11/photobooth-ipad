import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var capturedImage: UIImage?
    @Published var isReady: Bool = false
    @Published var error: CameraError?

    private var session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    enum CameraError: LocalizedError {
        case notAuthorized
        case setupFailed
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .notAuthorized: return "Accès à la caméra refusé. Vérifiez les réglages de confidentialité."
            case .setupFailed:   return "Impossible d'initialiser la caméra."
            case .captureFailed: return "La capture a échoué. Réessayez."
            }
        }
    }

    func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupSession() }
                    else { self?.error = .notAuthorized }
                }
            }
        default:
            DispatchQueue.main.async { self.error = .notAuthorized }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            DispatchQueue.main.async { self.error = .setupFailed }
            return
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        // High quality
        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .landscapeRight
            connection.isVideoMirrored = true
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self!.session)
                layer.videoGravity = .resizeAspectFill
                layer.connection?.videoOrientation = .landscapeRight
                self?.previewLayer = layer
                self?.isReady = true
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        output.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        session.stopRunning()
    }

    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async { self.captureCompletion?(nil) }
            return
        }

        // Fix orientation for front camera
        let fixed = image.fixedOrientation()
        DispatchQueue.main.async {
            self.capturedImage = fixed
            self.captureCompletion?(fixed)
        }
    }
}

// MARK: - UIImage Orientation Fix
extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }

    func mirrored() -> UIImage {
        guard let cgImage = cgImage else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .upMirrored)
    }
}
