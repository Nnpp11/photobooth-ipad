import Foundation
import SwiftUI
import Combine

// MARK: - AppState
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    @Published var currentSession: PhotoSession?
    @Published var capturedImages: [UIImage] = []
    @Published var finalImage: UIImage?
    @Published var isAdminUnlocked: Bool = false
    @Published var showAdminPanel: Bool = false
    @Published var isOffline: Bool = false
    @Published var pendingUploads: Int = 0

    func startSession(eventId: UUID) {
        currentSession = PhotoSession(eventId: eventId)
        capturedImages = []
        finalImage = nil
        navigate(to: .capture)
    }

    func navigate(to screen: AppScreen) {
        withAnimation(DS.Animation.smooth) {
            currentScreen = screen
        }
    }

    func resetToWelcome() {
        withAnimation(DS.Animation.smooth) {
            currentSession = nil
            capturedImages = []
            finalImage = nil
            currentScreen = .welcome
        }
    }
}

// MARK: - EventStore
class EventStore: ObservableObject {
    @Published var events: [Event] = []
    @Published var activeEvent: Event?
    @Published var sessions: [PhotoSession] = []
    @Published var mediaItems: [MediaItem] = []

    private let eventsKey = "photobooth.events"
    private let sessionsKey = "photobooth.sessions"
    private let mediaKey = "photobooth.media"

    init() {
        load()
        if events.isEmpty {
            createDefaultEvent()
        }
        activeEvent = events.first(where: { $0.isActive })
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        if let data = try? JSONEncoder().encode(mediaItems) {
            UserDefaults.standard.set(data, forKey: mediaKey)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([PhotoSession].self, from: data) {
            sessions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: mediaKey),
           let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) {
            mediaItems = decoded
        }
    }

    func createDefaultEvent() {
        let event = Event(
            name: "Mon Événement",
            date: Date(),
            subtitle: "Bienvenue !",
            hashtag: "#photobooth",
            captureMode: .single
        )
        events.append(event)
        activeEvent = event
        save()
    }

    func addSession(_ session: PhotoSession) {
        sessions.append(session)
        save()
    }

    func addMedia(_ media: MediaItem) {
        mediaItems.append(media)
        save()
    }

    func mediasForEvent(_ eventId: UUID) -> [MediaItem] {
        mediaItems.filter { $0.eventId == eventId }
    }

    func sessionsForEvent(_ eventId: UUID) -> [PhotoSession] {
        sessions.filter { $0.eventId == eventId }
    }

    // MARK: - Stats
    var totalSessions: Int { sessions.count }
    var pendingUploads: Int { mediaItems.filter { $0.uploadStatus == .pending }.count }

    // MARK: - Storage
    func saveImageLocally(_ image: UIImage, for mediaId: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        let filename = "\(mediaId.uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        try? data.write(to: url)
        return url.path
    }

    func loadImage(at path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }
}

// MARK: - Admin PIN
class AdminAuth: ObservableObject {
    private let pinKey = "photobooth.adminPin"
    private let defaultPin = "1234"

    var storedPin: String {
        UserDefaults.standard.string(forKey: pinKey) ?? defaultPin
    }

    func verify(_ pin: String) -> Bool {
        pin == storedPin
    }

    func changePin(_ newPin: String) {
        UserDefaults.standard.set(newPin, forKey: pinKey)
    }
}
