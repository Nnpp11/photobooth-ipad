import Foundation
import SwiftUI

// MARK: - Event
struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var subtitle: String = ""
    var hashtag: String = ""
    var galleryPrivacy: GalleryPrivacy = .unlisted
    var templateId: UUID?
    var captureMode: CaptureMode = .single
    var isActive: Bool = true
    var createdAt: Date = Date()
    var logoData: Data?
    var backgroundData: Data?
    var customQuestion: String = ""
    var requireDisclaimer: Bool = true
    var accentColorHex: String = "#C9A84C"

    enum GalleryPrivacy: String, Codable, CaseIterable {
        case `public` = "Publique"
        case unlisted = "Non listée"
        case `private` = "Privée"
    }
}

// MARK: - Capture Mode
enum CaptureMode: String, Codable, CaseIterable, Identifiable {
    case single   = "Photo simple"
    case grid     = "Grille"
    case strip    = "Bande photobooth"
    case gif      = "GIF"

    var id: String { rawValue }

    var frameCount: Int {
        switch self {
        case .single: return 1
        case .grid:   return 4
        case .strip:  return 3
        case .gif:    return 5
        }
    }

    var icon: String {
        switch self {
        case .single: return "camera"
        case .grid:   return "square.grid.2x2"
        case .strip:  return "rectangle.split.3x1"
        case .gif:    return "livephoto"
        }
    }

    var description: String {
        switch self {
        case .single: return "1 pose, rendu immédiat"
        case .grid:   return "4 poses, composition carrée"
        case .strip:  return "3 poses en bande verticale"
        case .gif:    return "5 frames, export animé"
        }
    }
}

// MARK: - Template
struct PhotoTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    var eventId: UUID
    var name: String
    var format: PrintFormat = .tenByFifteen
    var backgroundColor: String = "#0A0A0A"
    var logoData: Data?
    var overlayData: Data?
    var eventText: String = ""
    var dateText: String = ""
    var hashtag: String = ""
    var isLocked: Bool = false

    enum PrintFormat: String, Codable, CaseIterable {
        case tenByFifteen = "10×15 cm"
        case square       = "Carré"
        case portrait     = "Portrait"
        case landscape    = "Paysage"
    }
}

// MARK: - Session
struct PhotoSession: Identifiable, Codable {
    var id: UUID = UUID()
    var eventId: UUID
    var startedAt: Date = Date()
    var completedAt: Date?
    var status: SessionStatus = .active
    var consentPublic: Bool = false
    var disclaimerAccepted: Bool = false
    var guestEmail: String = ""
    var guestFirstName: String = ""
    var surveyAnswer: String = ""
    var mediaIds: [UUID] = []

    enum SessionStatus: String, Codable {
        case active, completed, abandoned
    }
}

// MARK: - Media
struct MediaItem: Identifiable, Codable {
    var id: UUID = UUID()
    var sessionId: UUID
    var eventId: UUID
    var type: MediaType = .photo
    var localPath: String = ""
    var remoteUrl: String?
    var thumbnailPath: String?
    var isPublic: Bool = false
    var uploadStatus: UploadStatus = .pending
    var createdAt: Date = Date()
    var frames: [String] = [] // paths for multi-frame

    enum MediaType: String, Codable {
        case photo, strip, grid, gif
    }

    enum UploadStatus: String, Codable {
        case pending, uploading, uploaded, failed
    }
}

// MARK: - Share Action
struct ShareAction: Identifiable, Codable {
    var id: UUID = UUID()
    var mediaId: UUID
    var channel: ShareChannel
    var target: String = ""
    var status: ActionStatus = .pending
    var retryCount: Int = 0
    var createdAt: Date = Date()

    enum ShareChannel: String, Codable {
        case qr, email, whatsapp, download
    }

    enum ActionStatus: String, Codable {
        case pending, sent, failed
    }
}

// MARK: - Print Job
struct PrintJob: Identifiable, Codable {
    var id: UUID = UUID()
    var mediaId: UUID
    var printerName: String = ""
    var copies: Int = 1
    var status: PrintStatus = .pending
    var error: String?
    var createdAt: Date = Date()

    enum PrintStatus: String, Codable {
        case pending, printing, done, failed
    }
}

// MARK: - App Navigation
enum AppScreen {
    case welcome
    case capture
    case preview
    case consent
    case share
    case print
    case admin
}
